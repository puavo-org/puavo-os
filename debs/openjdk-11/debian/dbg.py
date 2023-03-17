# Copyright 2016, Red Hat and individual contributors
# by the @authors tag.
# 
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
# 
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.
# 
# @authors Andrew Dinn

import gdb

import re
from gdb.FrameDecorator import FrameDecorator

# we rely on the unwinder API provided by gdb.7.10

_dump_frame = False
_have_unwinder = True
try:
    from gdb.unwinder import Unwinder
    gdb.write("Installing openjdk unwinder\n")
except ImportError:
    _have_unwinder = False
    # We need something here; it doesn't matter what as no unwinder
    # will ever be instantiated.
    Unwinder = object


def debug_write(msg):
    gdb.write(msg)
    # pass

def t(msg):
    gdb.write("%s\n" % msg)
    # pass

# debug_write("dbg.py\n")

# class providing various type conversions for gdb Value instances

class Types(object):
    # cache some basic primitive and pointer types
    byte_t = gdb.lookup_type('unsigned char')
    char_t = gdb.lookup_type('char')
    int_t = gdb.lookup_type('int')
    long_t = gdb.lookup_type('long')
    void_t = gdb.lookup_type('void')
    
    bytep_t = byte_t.pointer()
    charp_t = char_t.pointer()
    intp_t = int_t.pointer()
    longp_t = long_t.pointer()
    voidp_t = void_t.pointer()

    codeblobp_t = gdb.lookup_type('CodeBlob').pointer()
    cmethodp_t = gdb.lookup_type('CompiledMethod').pointer()
    nmethodp_t = gdb.lookup_type('nmethod').pointer()

    ptrp_t = voidp_t.pointer()

    # convert Values to primitive Values
    @classmethod
    def cast_byte(cls, value):
        return value.cast(cls.byte_t)

    @classmethod
    def cast_int(cls, value):
        return value.cast(cls.int_t)

    @classmethod
    def cast_long(cls, value):
        return value.cast(cls.long_t)

    # convert Values to pointer Values
    @classmethod
    def cast_bytep(cls, value):
        return value.cast(cls.bytep_t)

    @classmethod
    def cast_intp(cls, value):
        return value.cast(cls.intp_t)

    @classmethod
    def cast_longp(cls, value):
        return value.cast(cls.longp_t)

    @classmethod
    def cast_voidp(cls, value):
        return value.cast(cls.voidp_t)

    @classmethod
    def cast_ptrp(cls, value):
        return value.cast(cls.ptrp_t)

    # cast Value to pointer type then load and return contents as Value
    @classmethod
    def load_ptr(cls, value):
        return cls.cast_ptrp(cls.cast_ptrp(value).dereference())

    @classmethod
    def load_byte(cls, value):
        return cls.cast_bytep(value).dereference()

    @classmethod
    def load_int(cls, value):
        return cls.cast_intp(value).dereference()

    @classmethod
    def load_long(cls, value):
        return cls.cast_longp(value).dereference()

    # cast Value to int and return as python integer
    @classmethod
    def as_int(cls, value):
        return int(cls.cast_int(value))

    # cast Value to long and return as python integer
    @classmethod
    def as_long(cls, value):
        return int(cls.cast_long(value))

    # construct Value from integer x and cast to type t
    @classmethod
    def to_type(cls, x, t):
        return gdb.Value(x).cast(t)

    # construct voidp Value from integer x
    @classmethod
    def to_voidp(cls, x):
        return cls.to_type(x, cls.voidp_t)

    # construct void ** Value from integer x
    @classmethod
    def to_ptrp(cls, x):
        return cls.to_type(x, cls.ptrp_t)

# OpenJDK specific classes which understand the layout of the code
# heap and know how to translate a PC to an associated code blob and,
# from there to a method object. n.b. in some cases the latter step
# requires a frame base pointer bu tthat can be calculated using the
# code blob and stack pointer

# class encapsulating details of a specific heap

class CodeHeap:

    # track whether we have static initialized yet
    class_inited = False
    heap_block_type = None
    code_blob_type = None

    @classmethod
    def class_init(cls):
        # t("CodeHeap.class_init")
        if cls.class_inited:
            return
        # we can only proceed if we have the necessary heap symbols
        # if this excepts then we don't care
        cls.heap_block_type = gdb.lookup_type("HeapBlock").pointer()
        cls.code_blob_type = gdb.lookup_type("CodeBlob").pointer()
        cls.class_inited = True
    
    def __init__(self, heap):
        # t("CodeHeap.__init__")
        # make sure we have static inited successfuly
        self.class_init()
        # if we got here we are ok to create a new instance
        self.heap = heap
        self.name = str(heap['_name'])
        self.lo = Types.as_long(heap['_memory']['_low_boundary'])
        self.hi = Types.as_long(heap['_memory']['_high_boundary'])
        self.segmap = heap['_segmap']
        self.segmap_lo = self.segmap['_low']
        self.segment_size = int(heap['_segment_size'])
        self.log2_segment_size = int(heap['_log2_segment_size'])
        # debug_write("@@ heap.name = %s\n" % self.name)
        # debug_write("@@ heap.lo = 0x%x\n" % self.lo)
        # debug_write("@@ heap.hi = 0x%x\n" % self.hi)

    def inrange(self, x):
        # t("CodeHeap.inrange")
        return self.lo <= x and self.hi > x 
    def findblob(self, pc):
        # t("CodeHeap.findblob")
        x = Types.as_long(pc)
        # debug_write("@@ findblob(%s, 0x%x)\n" % (self.name, pc))
        # debug_write("@@ pc (%s) = 0x%x \n" % (str(pc.type), pc))
        # debug_write("@@ self.lo = 0x%x\n" % self.lo)
        # debug_write("@@ self.hi = 0x%x\n" % self.hi)
        # check pc is in this heap's range
        # t("if not self.inrange(x):")
        if not self.inrange(x):
            return None
        # debug_write("@@ pc in range\n")
        # t("segments = 0")
        segments = 0
        # debug_write("@@ segmap_lo (%s) = 0x%x\n" % (str(self.segmap_lo.type), self.segmap_lo))
        # debug_write("@@ self.lo = 0x%x \n" % self.lo)
        # debug_write("@@ self.log2_segment_size = 0x%x \n" % self.log2_segment_size)
        # t("offset = Types.as_long(pc - self.lo)")
        offset = Types.as_long(pc - self.lo)
        # debug_write("@@ offset = 0x%x\n" % offset)
        # t("shift = self.log2_segment_size")
        shift = self.log2_segment_size
        # debug_write("@@ shift = 0x%x\n" % shift)
        # t("segment = offset >> shift")
        segment = offset >> shift
        # segment = (offset >> self.log2_segment_size)
        #segment = offset >> (self.log2_segment_size & 0x31)
        # debug_write("@@ segment = 0x%x\n" % segment)
        # t("tag = (self.segmap_lo + segment).dereference() & 0xff")
        tag = (self.segmap_lo + segment).dereference() & 0xff
        # tag = Types.load_byte(self.segmap_lo + segment) & 0xff
        # debug_write("@@ tag (%s) = 0x%x\n" % (str(tag.type), tag))
        # t("while tag > 0 and segments < 64:")
        while tag > 0 and segments < 64:
            # t("segment = segment - tag")
            segment = segment - tag
            # debug_write("@@ segment = 0x%x\n" % segment)
            # t("tag = (self.segmap_lo + segment).dereference() & 0xff")
            tag = (self.segmap_lo + segment).dereference() & 0xff
            # debug_write("@@ tag (%s) = 0x%x\n" % (str(tag.type), tag))
            # t("segments += 1")
            segments += 1
            # t("if tag != 0:")
        if tag != 0:
            # t("return None")
            return None
        # debug_write("@@ lo = 0x%x\n" % self.lo)
        # debug_write("@@ segment << self.log2_segment_size = 0x%x\n" % (segment << self.log2_segment_size))
        # t("block_addr = self.lo + (segment << self.log2_segment_size)")
        block_addr = self.lo + (segment << self.log2_segment_size)
        # debug_write("@@ block_addr (%s) = 0x%x\n" % (str(block_addr.type), block_addr))
        # t("heap_block = gdb.Value(block_addr).cast(CodeHeap.heap_block_type)")
        heap_block = gdb.Value(block_addr).cast(CodeHeap.heap_block_type)
        # debug_write("@@ heap_block (%s) = 0x%x\n" % (str(heap_block.type), heap_block))
        # t("if heap_block['_header']['_used'] != 1:")
        if heap_block['_header']['_used'] != 1:
            # hmm, this is not meant to happen
            # t("return None")
            return None
        # t("blob = (heap_block + 1).cast(CodeHeap.code_blob_type)")
        blob = (heap_block + 1).cast(CodeHeap.code_blob_type)
        return blob

# class encapsulating access to code cache memory
# this is essentially all static as per the JVM class

class CodeCache:
    # track whether we have successfully intiialized
    class_inited = False
    # static heap start, lo and hi bounds for code addresses
    lo = 0
    hi = 0
    heap_count = 0
    heap_list = []

    @classmethod
    def class_init(cls):
        # t("CodeCache.class_init")
        if cls.class_inited:
            return
        # t("if cls.lo  == 0 or cls.hi == 0:")
        if cls.lo == 0 or cls.hi == 0:
            try:
                # t("cls.lo = gdb.parse_and_eval(\"CodeCache::_low_bound\")")
                lo = gdb.parse_and_eval("CodeCache::_low_bound")
                cls.lo = Types.as_long(lo)
                # debug_write("@@ CodeCache::_low_bound = 0x%x\n" % cls.lo)
                if cls.lo == 0:
                    return
                # t("cls.hi = gdb.parse_and_eval(\"CodeCache::_high_bound\")")
                hi = gdb.parse_and_eval("CodeCache::_high_bound")
                cls.hi = Types.as_long(hi)
                # debug_write("@@ CodeCache::_high_bound = 0x%x\n" % cls.hi)
                if cls.hi == 0:
                    return
            except Exception as arg:
                # debug_write("@@ %s\n" % arg)
                cls.lo = 0
                cls.hi = 0
                cls.class_inited = False
                raise

        # t("f cls.heap_list == []:")
        if cls.heap_list == []:
            try:
                # t("heaps = gdb.parse_and_eval(\"CodeCache::_heaps\")")
                heaps = gdb.parse_and_eval("CodeCache::_heaps")
                # debug_write("@@ CodeCache::_heaps (%s) = 0x%x\n" % (heaps.type, heaps))
                # t("len = int(heaps['_len'])")
                len = int(heaps['_len'])
                # debug_write("@@ CodeCache::_heaps->_len = %d\n" % len)
                # t("data = heaps['_data']")
                data = heaps['_data']
                # debug_write("@@ CodeCache::_heaps->_data = 0x%x\n" % data)
                # t("for i in range(0, len):")
                for i in range(0, len):
                    # t("heap = CodeHeap((data + i).dereference())")
                    heap = CodeHeap((data + i).dereference())
                    # t("cls.heap_list.append(heap)")
                    cls.heap_list.append(heap)
                    # t("cls.heap_count += 1")
                    cls.heap_count += 1
            except Exception as arg:
                # debug_write("@@ %s\n" % arg)
                cls.heap_list = []
                cls.heap_count = 0
                cls.class_inited = False
                raise
        cls.class_inited = True

    @classmethod
    def inrange(cls, pc):
        # t("CodeCache.inrange")
        # make sure we are initialized
        cls.class_init()
        # if we got here we can use the heaps
        x = Types.as_long(pc)
        # t("return cls.lo <= x and cls.hi > x")
        return cls.lo <= x and cls.hi > x

    @classmethod
    def makestr(cls, charcnt, charptr):
        # t("CodeCache.makestr")
        #res = ""
        #for i in range(0, charcnt):
        #    c = (charptr + i).dereference()
        #    res = ("%s%c" % (res, c))
        #return res
        # debug_write("charcnt = %d charptr = %s\n" % (charcnt, str(charptr)))
        return charptr.string("ascii", "ignore", charcnt)

    # given a PC find the associated OpenJDK code blob instance
    @classmethod
    def findblob(cls, pc):
        # t("CodeCache.findblob")
        # make sure we are initialized
        cls.class_init()
        # if we got here we can use the heaps
        if not cls.inrange(pc):
            raise gdb.GdbError("dbg.findblob : address 0x%x is not in range!" % pc)
        for heap in cls.heap_list:
            try:
                # t("blob = heap.findblob(pc)")
                blob = heap.findblob(pc)
            except Exception as arg:
                # debug_write("@@ findblob excepted %s\n" % str(arg)) 
                # t("blob = None")
                blob = None
            # t("if blob != None:")
            if blob != None:
                # t("name=str(blob['_name'])")
                name=str(blob['_name'])
                # debug_write("@@ blob(0x%x) -> %s\n" % (pc, name))
                # t("return blob")
                return blob
        # t("raise gdb.GdbError")
        raise gdb.GdbError("dbg.findblob : no blob for inrange address 0x%x!" % pc)

# abstract over some constants for stack frame layout

class FrameConstants(object):
    class_inited = False
    _sender_sp_offset = 0
    _interpreter_frame_sender_sp_offset = 0
    _interpreter_frame_method_offset = 0
    _interpreter_frame_bcp_offset = 0
    @classmethod
    def class_init(cls):
        if cls.class_inited:
            return
        cls._interpreter_frame_sender_sp_offset = int(gdb.parse_and_eval("frame::interpreter_frame_sender_sp_offset"))
        cls._sender_sp_offset = int(gdb.parse_and_eval("frame::sender_sp_offset"))
        cls._interpreter_frame_method_offset = int(gdb.parse_and_eval("frame::interpreter_frame_method_offset"))
        cls._interpreter_frame_bcp_offset = int(gdb.parse_and_eval("frame::interpreter_frame_bcp_offset"))
        # only set if we got here with no errors
        cls.class_inited = True
    @classmethod
    def sender_sp_offset(cls):
        cls.class_init()
        return cls._sender_sp_offset
    @classmethod
    def interpreter_frame_sender_sp_offset(cls):
        cls.class_init()
        return cls._interpreter_frame_sender_sp_offset
    @classmethod
    def interpreter_frame_method_offset(cls):
        cls.class_init()
        return cls._interpreter_frame_method_offset
    @classmethod
    def interpreter_frame_bcp_offset(cls):
        cls.class_init()
        return cls._interpreter_frame_bcp_offset

# class which knows how to read a compressed stream of bytes n.b. at
# the moment we only need to know how to read bytes and ints

class CompressedStream:
    # important constants for compressed stream read
    BitsPerByte = 8
    lg_H = 6
    H = 1 << lg_H
    L = (1 << BitsPerByte) - H
    MAX_i = 4

    def __init__(self, data):
        # data is a gdb.Value of type 'byte *'
        self.data = data
        self.pos = 0
    # retrieve the byte at offset pos
    def at(self, pos):
        return int(Types.load_byte(self.data + pos))
    # read and return the next byte
    def read(self):
        # t("CompressedStream.read()")
        pos = self.pos
        b = self.at(pos)
        self.pos = pos+1
        return b
    def read_int(self):
        # t("CompressedStream.read_int()")
        b0 = self.read()
        # debug_write("b0 = 0x%x\n" % b0)
        if b0 < CompressedStream.L:
            return b0
        return self.read_int_mb(b0)
    def read_signed_int(self):
        # t("CompressedStream.read_signed_int()")
        return self.decode_sign(self.read_int())
    def decode_sign(self, x):
        # t("CompressedStream.decode_sign()")
        return (x >> 1) ^ (0 - (x & 1))
    def read_int_mb(self, b):
        t# ("CompressedStream.read_int_mb()")
        sum = b
        pos = self.pos
        # debug_write("pos = %d\n" % pos)
        # debug_write("sum = 0x%x\n" % sum)
        lg_H_i = CompressedStream.lg_H
        i = 0
        while (True):
            b_i = self.at(pos + i)
            # debug_write("b_%d = %d\n" % (i, b_i))
            sum += (b_i << lg_H_i)
            # debug_write("sum = 0x%x\n" % sum)
            i += 1
            if b_i < CompressedStream.L or i == CompressedStream.MAX_i:
                self.pos = pos + i
                # debug_write("self.pos = %d\n" % self.pos)
                return sum
            lg_H_i += CompressedStream.lg_H


# class which knows how to find method and bytecode
# index pairs from a pc associated with a given compiled
# method. n.b. there may be more than one such pair
# because of inlining.

class MethodBCIReader:
    pcdescstar_t = None
    class_inited = False
    @classmethod
    def class_init(cls):
        # t("MethodBCIReader.class_init")
        if cls.class_inited:
            return
        # cache some useful types
        cls.pcdesc_p = gdb.lookup_type("PcDesc").pointer()
        cls.metadata_p = gdb.lookup_type("Metadata").pointer()
        cls.metadata_pp = cls.metadata_p.pointer()
        cls.method_p = gdb.lookup_type("Method").pointer()
        cls.class_inited = True

    @classmethod
    def as_pcdesc_p(cls, val):
        return Types.to_type(val, cls.pcdesc_p)

    def __init__(self, nmethod, method):
        # t("MethodBCIReader.__init__")
        # ensure we have cached the necessary types
        self.class_init()
        # need to unpack pc scopes
        self.nmethod = nmethod
        self.method = method
        # debug_write("nmethod (%s) = 0x%x\n" % (str(nmethod.type), Types.as_long(nmethod)))
        blob = Types.to_type(nmethod, Types.codeblobp_t);
        self.code_begin = Types.as_long(blob['_code_begin'])
        self.code_end = Types.as_long(blob['_code_end'])
        scopes_pcs_begin_offset = Types.as_int(nmethod['_scopes_pcs_offset'])
        # debug_write("scopes_pcs_begin_offset = 0x%x\n" % scopes_pcs_begin_offset)
        scopes_pcs_end_offset = Types.as_int(nmethod['_dependencies_offset'])
        # debug_write("scopes_pcs_end_offset = 0x%x\n" % scopes_pcs_end_offset)
        header_begin = Types.cast_bytep(nmethod)
        self.scopes_pcs_begin = self.as_pcdesc_p(header_begin + scopes_pcs_begin_offset)
        # debug_write("scopes_pcs_begin (%s) = 0x%x\n" % (str(self.scopes_pcs_begin.type), Types.as_long(self.scopes_pcs_begin)))
        self.scopes_pcs_end = self.as_pcdesc_p(header_begin + scopes_pcs_end_offset)
        # debug_write("scopes_pcs_end (%s) = 0x%x\n" % (str(self.scopes_pcs_end.type), Types.as_long(self.scopes_pcs_end)))

    def find_pc_desc(self, pc_off):
        lower = self.scopes_pcs_begin
        upper = self.scopes_pcs_end - 1
        if lower == upper:
            return None
        # non-empty table always starts with lower as a sentinel with
        # offset -1 and will have at least one real offset beyond that
        next = lower + 1
        while next < upper and next['_pc_offset'] <= pc_off:
            next = next + 1
        # use the last known bci below this pc
        return next - 1

    def pc_desc_to_method_bci_stack(self, pc_desc):
        scope_decode_offset = Types.as_int(pc_desc['_scope_decode_offset'])
        if scope_decode_offset == 0:
            return [ { 'method': self.method, 'bci': 0 } ]
        nmethod = self.nmethod
        # debug_write("nmethod = 0x%x\n" % nmethod)
        # debug_write("pc_desc = 0x%x\n" % Types.as_long(pc_desc))
        base = Types.cast_bytep(nmethod)
        # scopes_data_offset = Types.as_int(nmethod['_scopes_data_offset'])
        # scopes_base = base + scopes_data_offset
        scopes_base = nmethod['_scopes_data_begin']
        # debug_write("scopes_base = 0x%x\n" % Types.as_long(scopes_base))
        metadata_offset = Types.as_int(nmethod['_metadata_offset'])
        metadata_base = Types.to_type(base + metadata_offset, self.metadata_pp)
        # debug_write("metadata_base = 0x%x\n" % Types.as_long(metadata_base))
        scope = scopes_base + scope_decode_offset
        # debug_write("scope = 0x%x\n" % Types.as_long(scope))
        stream = CompressedStream(scope)
        # debug_write("stream = %s\n" % stream)
        sender = stream.read_int()
        # debug_write("sender = %s\n" % sender)
        # method name is actually in metadata
        method_idx = stream.read_int()
        method_md = (metadata_base + (method_idx - 1)).dereference()
        methodptr = Types.to_type(method_md, self.method_p)
        method = Method(methodptr)
        # bci is offset by -1 to allow range [-1, ..., MAX_UINT)
        bci = stream.read_int() - 1
        # debug_write("method,bci = %s,0x%x\n" % (method.get_name(), bci))
        result = [ { 'method': method, 'bci': bci } ]
        while sender > 0:
            # debug_write("\nsender = 0x%x\n" % sender)
            stream = CompressedStream(scopes_base + sender)
            sender = stream.read_int()
            method_idx = stream.read_int()
            method_md = (metadata_base + (method_idx - 1)).dereference()
            methodptr = Types.to_type(method_md, self.method_p)
            method = Method(methodptr)
            # bci is offset by -1 to allow range [-1, ..., MAX_UINT)
            bci = stream.read_int() - 1
            # debug_write("method,bci = %s,0x%x\n" % (method.get_name(), bci))
            result.append( { 'method': method, 'bci': bci } )
        return result

    def pc_to_method_bci_stack(self, pc):
        # need to search unpacked pc scopes
        if pc < self.code_begin or pc >= self.code_end:
            return None
        pc_off = pc - self.code_begin
        # debug_write("\npc_off = 0x%x\n" % pc_off) 
        pc_desc = self.find_pc_desc(pc_off)
        if pc_desc is None:
            return None
        return self.pc_desc_to_method_bci_stack(pc_desc)

# class which knows how to read a method's line
# number table, translating bytecode indices to line numbers
class LineReader:
    # table is a gdb.Value of type 'byte *' (strictly 'u_char *' in JVM code)
    def __init__(self, table):
        # t("LineReader.init")
        self.table = table
        self.translations = {}
    def bc_to_line(self, bci):
        # t("LineReader.bc_to_line()")
        try:
            return self.translations[bci]
        except Exception as arg:
            line = self.compute_line(bci)
            if line >= 0:
                self.translations[bci] = line
            return line
    def compute_line(self, bci):
        # t("LineReader.compute_line()")
        # debug_write("table = 0x%x\n" % self.table)
        bestline = -1
        self.stream = CompressedStream(self.table)
        self._bci = 0
        self._line = 0
        while self.read_pair():
            nextbci = self._bci
            nextline = self._line
            if nextbci >= bci:
                return nextline
            else:
                bestline = nextline
        return bestline
    def read_pair(self):
        # t("LineReader.read_pair()")
        next = self.stream.read()
        # debug_write("next = 0x%x\n" % next)
        if next == 0:
            return False
        if next == 0xff:
            self._bci = self._bci + self.stream.read_signed_int()
            self._line = self._line + self.stream.read_signed_int()
        else:
            self._bci = self._bci + (next >> 3)
            self._line = self._line + (next & 0x7)
        # debug_write("_bci = %d\n" % self._bci)
        # debug_write("_line = %d\n" % self._line)
        return True

# class to provide access to data relating to a Method object
class Method(object):
    def __init__(self, methodptr):
        self.methodptr = methodptr;
        self.name = None
        const_method = self.methodptr['_constMethod']
        bcbase = Types.cast_bytep(const_method + 1)
        bytecode_size =  Types.as_int(const_method['_code_size'])
        lnbase = Types.cast_bytep(bcbase + bytecode_size)
        self.line_number_reader = LineReader(lnbase)

    def get_name(self):
        if self.name == None:
            self.make_name(self.methodptr)
        return self.name
        
    def get_klass_path(self):
        if self.name == None:
            self.make_name(self.methodptr)
        return self.klass_path
    
    def get_line(self, bci):
        if bci < 0:
            bci = 0
        return self.line_number_reader.bc_to_line(bci)

    def make_name(self, methodptr):
        const_method = methodptr['_constMethod']
        constant_pool = const_method['_constants']
        constant_pool_base = Types.cast_voidp((constant_pool + 1))
        klass_sym = constant_pool['_pool_holder']['_name']
        klass_name = klass_sym['_body'].cast(gdb.lookup_type("char").pointer())
        klass_name_length = int(klass_sym['_length'])
        klass_path = CodeCache.makestr(klass_name_length, klass_name)
        self.klass_str = klass_path.replace("/", ".")
        dollaridx = klass_path.find('$')
        if dollaridx >= 0:
            klass_path = klass_path[0:dollaridx]
        self.klass_path = klass_path + ".java"
        method_idx = const_method['_name_index']
        method_sym = (constant_pool_base + (8 * method_idx)).cast(gdb.lookup_type("Symbol").pointer().pointer()).dereference()
        method_name = method_sym['_body'].cast(gdb.lookup_type("char").pointer())
        method_name_length = int(method_sym['_length'])
        self.method_str =  CodeCache.makestr(method_name_length, method_name)

        sig_idx = const_method['_signature_index']
        sig_sym = (constant_pool_base + (8 * sig_idx)).cast(gdb.lookup_type("Symbol").pointer().pointer()).dereference()
        sig_name = sig_sym['_body'].cast(gdb.lookup_type("char").pointer())
        sig_name_length = int(sig_sym['_length'])
        sig_str = CodeCache.makestr(sig_name_length, sig_name)
        self.sig_str = self.make_sig_str(sig_str)
        self.name = self.klass_str + "." + self.method_str + self.sig_str
            
    def make_sig_str(self, sig):
        in_sym_name = False
        sig_str = ""
        prefix=""
        for i, c in enumerate(sig):
            if c == "(":
                sig_str = sig_str + c
            elif c == ")":
                # ignore return type
                return sig_str + c
            elif in_sym_name == True:
                if c == ";":
                    in_sym_name = False
                elif c == "/":
                    sig_str = sig_str + "."
                else:
                    sig_str = sig_str + c
            elif c == "L":
                sig_str = sig_str + prefix
                prefix = ","
                in_sym_name = True
            elif c == "B":
                sig_str = sig_str + prefix + "byte"
                prefix = ","
            elif c == "S":
                sig_str = sig_str + prefix + "short"
                prefix = ","
            elif c == "C":
                sig_str = sig_str + prefix + "char"
                prefix = ","
            elif c == "I":
                sig_str = sig_str + prefix + "int"
                prefix = ","
            elif c == "J":
                sig_str = sig_str + prefix + "long"
                prefix = ","
            elif c == "F":
                sig_str = sig_str + prefix + "float"
                prefix = ","
            elif c == "D":
                sig_str = sig_str + prefix + "double"
                prefix = ","
            elif c == "Z":
                sig_str = sig_str + prefix + "boolean"
                prefix = ","
        return sig_str

# This represents a method in a JIT frame for the purposes of
# display. There may be more than one method associated with
# a (compiled) frame because of inlining. The MethodInfo object
# associated with a JIT frame creates a list of decorators.
# Interpreted and stub MethodInfo objects insert only one
# decorator. Compiled MethodInfo objects insert one for the
# base method and one for each inlined method found at the
# frame PC address.
class OpenJDKFrameDecorator(FrameDecorator):
    def __init__(self, base, methodname, filename, line):
        super(FrameDecorator, self).__init__()
        self._base = base
        self._methodname = methodname
        self._filename = filename
        self._line = line

    def function(self):
        try:
            # t("OpenJDKFrameDecorator.function")
            return self._methodname
        except Exception as arg:
            gdb.write("!!! function oops !!! %s\n" % arg)
            return None

    def method_name(self):
        return _methodname

    def filename(self):
        try:
            return self._filename
        except Exception as arg:
            gdb.write("!!! filename oops !!! %s\n" % arg)
            return None

    def line(self):
        try:
            return self._line
        except Exception as arg:
            gdb.write("!!! line oops !!! %s\n" % arg)
            return None

# A frame filter for OpenJDK.
class OpenJDKFrameFilter(object):
    def __init__(self, unwinder):
        self.name="OpenJDK"
        self.enabled = True
        self.priority = 100
        self.unwinder = unwinder

    def maybe_wrap_frame(self, frame):
        # t("OpenJDKFrameFilter.maybe_wrap_frame")
        if self.unwinder is None:
            return [ frame ]
        # t("unwindercache = self.unwinder.unwindercache")
        unwindercache = self.unwinder.unwindercache
        if unwindercache is None:
            return [ frame ]
        # t("base = frame.inferior_frame()")
        base = frame.inferior_frame()
        # t("sp = Types.as_long(base.read_register('rsp'))")
        sp = base.read_register('rsp')
        x = Types.as_long(sp)
        # debug_write("@@ get info at unwindercache[0x%x]\n" % x)
        try:
            cache_entry = unwindercache[x]
        except Exception as arg:
            # n.b. no such entry throws an exception
            # just ignore and use existing frame
            return [ frame ]
        try:
            if cache_entry is None:
                # debug_write("@@ lookup found no cache_entry\n")
                return [ frame ]
            elif cache_entry.codetype == "unknown":
                # debug_write("@@ lookup found unknown cache_entry\n")
                return [ frame ]
            else:
                # debug_write("@@ got cache_entry for blob 0x%x at unwindercache[0x%x]\n" % (cache_entry.blob, x))
                method_info = cache_entry.method_info
                if method_info == None:
                    return [ frame ]
                else:
                    return method_info.decorate(frame)
        except Exception as arg:
            gdb.write("!!! maybe_wrap_frame oops !!! %s\n" % arg)
            return [ frame ]

    def flatten(self, list_of_lists):
        return [x for y in list_of_lists for x in y ]

    def filter(self, frame_iter):
        # return map(self.maybe_wrap_frame, frame_iter)
        return self.flatten( map(self.maybe_wrap_frame, frame_iter) )

    
# A frame id class, as specified by the gdb unwinder API.
class OpenJDKFrameId(object):
    def __init__(self, sp, pc):
        # t("OpenJDKFrameId.__init__")
        self.sp = sp
        self.pc = pc

# class hierarchy to record details of different code blobs
# the class implements functionality required by the frame decorator

class MethodInfo(object):
    def __init__(self, entry):
        self.blob = entry.blob
        self.pc = Types.as_long(entry.pc)
        self.sp = Types.as_long(entry.sp)
        if entry.bp is None:
            self.bp = 0
        else:
            self.bp = Types.as_long(entry.bp)

    def decorate(self, frame):
        return [ frame ]

# info for stub frame

class StubMethodInfo(MethodInfo):
    def __init__(self, entry, name):
        super(StubMethodInfo, self).__init__(entry)
        self.name = name

    def decorate(self, frame):
        return [ OpenJDKFrameDecorator(frame, self.name, None, None) ]

# common info for compiled, native or interpreted frame
class JavaMethodInfo(MethodInfo):

    def __init__(self, entry):
        super(JavaMethodInfo, self).__init__(entry)

    def cache_method_info(self):
        methodptr = self.get_methodptr()
        self.method = Method(methodptr)


    def get_method(self):
        return self.method

    def method_name(self):
        return self.get_method().get_name()

    def filename(self):
        return self.get_method().get_klass_path()

    def decorate(self, frame):
        return [ OpenJDKFrameDecorator(frame, self.method_name(), self.filename(), None) ]

# info for compiled frame

class CompiledMethodInfo(JavaMethodInfo):

    def __init__(self, entry):
        # t("CompiledMethodInfo.__init__")
        super(CompiledMethodInfo,self).__init__(entry)
        blob = self.blob
        cmethod = Types.to_type(blob, Types.cmethodp_t)
        nmethod = Types.to_type(blob, Types.nmethodp_t)
        self.methodptr = cmethod['_method']
        const_method = self.methodptr['_constMethod']
        bcbase = Types.cast_bytep(const_method + 1)
        self.code_begin = Types.as_long(blob['_code_begin'])
        # get bc and line number info from method
        self.cache_method_info()
        # get PC to BCI translator from the nmethod
        self.bytecode_index_reader = MethodBCIReader(nmethod, self.method)
        # t("self.method_bci_stack = self.bytecode_index_reader.pc_to_method_bci_stack(self.pc)")
        self.method_bci_stack = self.bytecode_index_reader.pc_to_method_bci_stack(self.pc)

    # subclasses need to compute their method pointer

    def get_methodptr(self):
        return self.methodptr

    def format_method_name(self, method, is_outer):
        name = method.get_name()
        if is_outer:
            return ("[compiled offset=0x%x] %s" % (self.pc - self.code_begin, name))
        else:
            return ("[inlined] %s" % name)

    def make_decorator(self, frame, pair, is_outer):
        # t("make_decorator")
        method = pair['method']
        bci = pair['bci']
        methodname = self.format_method_name(method, is_outer)
        filename = method.get_klass_path()
        line = method.get_line(bci)
        if line < 0:
            line = None
        decorator = OpenJDKFrameDecorator(frame, methodname, filename, line)
        return decorator

    def decorate(self, frame):
        if self.method_bci_stack == None:
            return [ frame ]
        else:
            try:
                decorators = []
                pairs = self.method_bci_stack
                # debug_write("converting method_bci_stack = %s\n" % self.method_bci_stack)
                l = len(pairs)
                for i in range(l):
                    pair = pairs[i]
                    # debug_write("decorating pair %s\n" % pair)
                    decorator = self.make_decorator(frame, pair, i == (l - 1))
                    decorators.append(decorator)
                return decorators
            except Exception as arg:
                gdb.write("!!! decorate oops %s !!!\n" % arg)
                return [ frame ]

# info for native frame

class NativeMethodInfo(JavaMethodInfo):

    def __init__(self, entry):
        # t("NativeMethodInfo.__init__")
        super(NativeMethodInfo,self).__init__(entry)
        blob = self.blob
        cmethod = Types.to_type(blob, Types.cmethodp_t)
        nmethod = Types.to_type(blob, Types.nmethodp_t)
        self.methodptr = cmethod['_method']
        const_method = self.methodptr['_constMethod']
        bcbase = Types.cast_bytep(const_method + 1)
        self.code_begin = Types.as_long(blob['_code_begin'])
        # get bc and line number info from method
        self.cache_method_info()

    # subclasses need to compute their method pointer

    def get_methodptr(self):
        return self.methodptr

    def format_method_name(self, method):
        name = method.get_name()
        return ("[native offset=0x%x] %s" % (self.pc - self.code_begin, name))

    def method_name(self):
        return self.format_method_name(self.method)

# info for interpreted frame

class InterpretedMethodInfo(JavaMethodInfo):

    def __init__(self, entry, bcp):
        super(InterpretedMethodInfo,self).__init__(entry)
        # interpreter frames store methodptr in slot 3
        methodptr_offset = FrameConstants.interpreter_frame_method_offset() * 8
        methodptr_addr = gdb.Value((self.bp + methodptr_offset) & 0xffffffffffffffff)
        methodptr_slot = methodptr_addr.cast(gdb.lookup_type("Method").pointer().pointer())
        self.methodptr = methodptr_slot.dereference()
        # bytecode immediately follows const method
        const_method = self.methodptr['_constMethod']
        bcbase = Types.cast_bytep(const_method + 1)
        # debug_write("@@ bcbase = 0x%x\n" % Types.as_long(bcbase))
        bcp_offset = FrameConstants.interpreter_frame_bcp_offset() * 8
        if bcp is None:
            # interpreter frames store bytecodeptr in slot 8
            bcp_addr = gdb.Value((self.bp + bcp_offset) & 0xffffffffffffffff)
            bcp_val = Types.cast_bytep(Types.load_ptr(bcp_addr))
        else:
            bcp_val =  Types.cast_bytep(bcp)
            # sanity check the register value -- it is sometimes off
            # when returning from a call out
            bcoff = Types.as_long(bcp_val - bcbase)
            if bcoff < 0 or bcoff >= 0x10000:
                # use the value in the frame slot
                bcp_addr = gdb.Value((self.bp + bcp_offset) & 0xffffffffffffffff)
                bcp_val = Types.cast_bytep(Types.load_ptr(bcp_addr))
        self.bcoff = Types.as_long(bcp_val - bcbase)
        # debug_write("@@ bcoff = 0x%x\n" % self.bcoff)
        # line number table immediately following bytecode
        bytecode_size =  Types.as_int(const_method['_code_size'])
        self.is_native = (bytecode_size == 0)
        # n.b. data in compressed line_number_table block is u_char
        # debug_write("bytecode_size = 0x%x\n" % bytecode_size)
        lnbase = Types.cast_bytep(bcbase + bytecode_size)
        # debug_write("lnbase = 0x%x\n" % Types.as_long(lnbase))
        self.line_number_reader = LineReader(lnbase)
        self.cache_method_info()

    def get_methodptr(self):
        return self.methodptr

    def format_method_name(self, method):
        name = method.get_name()
        if self.is_native:
            return "[native] " + name
        else:
            return ("[interpreted: bc = %d] " % self.bcoff) + name

    def line(self):
        line = self.line_number_reader.bc_to_line(self.bcoff)
        # debug_write("bc_to_line(%d) = %d\n" % (self.bcoff, line))
        if line < 0:
            line = None
        return line

    def decorate(self, frame):
        method = self.get_method()
        return [ OpenJDKFrameDecorator(frame, self.format_method_name(method), method.get_klass_path(), self.line()) ]


class OpenJDKUnwinderCacheEntry(object):
    def __init__(self, blob, sp, pc, bp, bcp, name, codetype):
        # t("OpenJDKUnwinderCacheEntry.__init__")
        self.blob = blob
        self.sp = sp
        self.pc = pc
        self.bp = bp
        self.codetype = codetype
        try:
            if codetype == "compiled":
                self.method_info = CompiledMethodInfo(self)
            elif codetype == "native":
                self.method_info = NativeMethodInfo(self)
            elif codetype == "interpreted":
                self.method_info = InterpretedMethodInfo(self, bcp)
            elif codetype == "stub":
                self.method_info = StubMethodInfo(self, name)
            else:
                self.method_info = None
        except Exception as arg:
            gdb.write("!!! failed to cache info for %s frame [pc: 0x%x sp:0x%x bp 0x%x] !!!\n!!! %s !!!\n" % (codetype, pc, sp, bp, arg))
            self.method_info = None

# an unwinder class, an instance of which can be registered with gdb
# to handle unwinding of frames.

class OpenJDKUnwinder(Unwinder):
    def __init__(self):
        # t("OpenJDKUnwinder.__init__")
        super(OpenJDKUnwinder, self).__init__("OpenJDKUnwinder")
        # blob name will be in format '0xHexDigits "AlphaNumSpaces"'
        self.matcher=re.compile('^0x[a-fA-F0-9]+ "(.*)"$')
        self.unwindercache = {}
        self.invocations = {}

    # the method that gets called by the pyuw_sniffer
    def __call__(self, pending_frame):
        # sometimes when we call into python gdb routines
        # the call tries to re-establish the frame and ends
        # up calling the frame sniffer recursively
        #
        # so use a list keyed by thread to avoid recursive calls
        # t("OpenJDKUnwinder.__call__")
        thread = gdb.selected_thread()
        if self.invocations.get(thread) != None:
            # debug_write("!!! blocked %s !!!\n" % str(thread))
            return None
        try:
            # debug_write("!!! blocking %s !!!\n" % str(thread))
            self.invocations[thread] = thread
            result = self.call_sub(pending_frame)
            # debug_write("!!! unblocking %s !!!\n" % str(thread)) 
            self.invocations[thread] = None
            return result
        except Exception as arg:
            gdb.write("!!! __call__ oops %s !!!\n" % arg)
            # debug_write("!!! unblocking %s !!!\n" % str(thread))
            self.invocations[thread] = None
            return None

    def call_sub(self, pending_frame):
        # t("OpenJDKUnwinder.__call_sub__")
        # debug_write("@@ reading pending frame registers\n")
        pc = pending_frame.read_register('rip')
        # debug_write("@@ pc = 0x%x\n" % Types.as_long(pc))
        sp = pending_frame.read_register('rsp')
        # debug_write("@@ sp = 0x%x\n" % Types.as_long(sp))
        bp = pending_frame.read_register('rbp')
        # debug_write("@@ bp = 0x%x\n" % Types.as_long(bp))
        try:
            if not CodeCache.inrange(pc):
                # t("not CodeCache.inrange(0x%x)\n" % pc)
                return None
        except Exception as arg:
            # debug_write("@@ %s\n" % arg)
            return None
        if _dump_frame:
            debug_write("     pc = 0x%x\n" % Types.as_long(pc))
            debug_write("     sp = 0x%x\n" % Types.as_long(sp))
            debug_write("     bp = 0x%x\n" % Types.as_long(bp))
        # this is a Java frame so we need to return unwind info
        #
        # the interpreter keeps the bytecode pointer (bcp) in a
        # register and saves it to the stack when it makes a call to
        # another Java method or to C++. if the current frame has a
        # bcp register value then we pass it in case the pending frame
        # is an intrepreter frame. that ensures we use the most up to
        # date bcp when the inferior has stopped at the top level in a
        # Java interpreted frame. it also saves us doing a redundant
        # stack read when the pending frame sits below a non-JITted
        # (C++) frame. n.b. if the current frame is a JITted frame
        # (i.e. one that we have already unwound) then rbp will not be
        # present. that's ok because the frame decorator can still
        # find the latest bcp value on the stack.
        bcp = pending_frame.read_register('r13')
        try:
            # convert returned value to a python int to force a check that
            # the register is defined. if not this will except
            bcp = gdb.Value(int(bcp))
            # debug_write("@@ bcp = 0x%x\n" % Types.as_long(bcp))
        except Exception as arg:
            # debug_write("@@ !!! call_sub oops %s !!! \n" % arg)
            bcp = None
            # debug_write("@@ bcp = None\n")
        # t("blob = CodeCache.findblob(pc)")
        blob = CodeCache.findblob(pc)
        # t("if blob is None:")
        if blob is None:
            # t("return None")
            return None
        # if the blob is an nmethod then we use the frame
        # size to identify the frame base otherwise we
        # use the value in rbp
        # t("name = str(blob['_name'])")
        name = str(blob['_name'])
        # blob name will be in format '0xHexDigits "AlphaNumSpaces"'
        # and we just want the bit between the quotes
        m = self.matcher.match(name)
        if not m is None:
            # debug_write("@@ m.group(1) == %s\n" % m.group(1))
            name = m.group(1)
        if name == "nmethod":
            # debug_write("@@ compiled %s\n" % name)
            codetype = 'compiled'
            # TODO -- need to check if frame is complete
            # i.e. if ((char *)pc - (char *)blob) > blob['_code_begin'] + blob['_frame_complete_offset']
            # if not then we have not pushed a frame.
            # what do we do then? use SP as BP???
            frame_size = blob['_frame_size']
            # debug_write("@@ frame_size = 0x%x\n" % int(frame_size))
            # n.b. frame_size includes stacked rbp and rip hence the -2
            bp = sp + ((frame_size - 2) * 8)
            # debug_write("@@ revised bp = 0x%x\n" % Types.as_long(bp))
        elif name == "native nmethod":
            # debug_write("@@ native %s \n" % name)
            codetype = "native"
        elif name == "Interpreter":
            # debug_write("@@ interpreted %s\n" %name)
            codetype = "interpreted"
        elif name[:4] == "Stub":
            # debug_write("@@ stub %s\n" % name)
            codetype = "stub"
        else:
            # debug_write("@@ unknown %s\n" % name)
            codetype = "unknown"
        # cache details of the current frame
        x = Types.as_long(sp)
        # debug_write("@@ add %s cache entry for blob 0x%x at unwindercache[0x%x]\n" % (codetype, blob, x))
        self.unwindercache[x] = OpenJDKUnwinderCacheEntry(blob, sp, pc, bp, bcp, name, codetype)
        # t("next_bp = Types.load_long(bp)")
        next_bp = Types.load_long(bp)
        # t("next_pc = Types.load_long(bp + 8)")
        next_pc = Types.load_long(bp + 8)
        # next_sp is normally just 2 words below current bp
        # but for interpreted frames we need to skip locals
        # so we pull caller_sp from the frame
        if codetype == "interpreted":
            interpreter_frame_sender_sp_offset = FrameConstants.interpreter_frame_sender_sp_offset() * 8
            # interpreter frames store sender sp in slot 1
            next_sp = Types.load_long(bp + interpreter_frame_sender_sp_offset)
        else:
            sender_sp_offset = FrameConstants.sender_sp_offset() * 8
            next_sp = bp + sender_sp_offset
        # create unwind info for this frame
        # t("frameid = OpenJDKFrameId(...)")
        frameid = OpenJDKFrameId(Types.to_voidp(next_sp),
                                 Types.to_type(next_pc, pc.type))
        # debug_write("@@ created frame id\n")
        # t("unwind_info = pending_frame.create_unwind_info(frameid)")
        unwind_info = pending_frame.create_unwind_info(frameid)
        # debug_write("@@ created unwind info\n")
        # debug_write("@@ next_bp = 0x%x\n" % next_bp)
        # debug_write("@@ next_pc = 0x%x\n" % next_pc)
        # debug_write("@@ next_sp = 0x%x\n" % next_sp)
        # we must calculate pc, sp and bp.
        #
        # for now we only add the minimum of registers that we know
        # are valid.
        unwind_info.add_saved_register('rip', next_pc)
        unwind_info.add_saved_register('rsp', next_sp)
        unwind_info.add_saved_register('rbp', next_bp)
        if _dump_frame:
            debug_write("next pc = 0x%x\n" % Types.as_long(next_pc))
            debug_write("next sp = 0x%x\n" % Types.as_long(next_sp))
            debug_write("next bp = 0x%x\n" % Types.as_long(next_bp))
        # t("return unwind_info")
        return unwind_info

# register the unwinder globally [probably really needs to be
# registered solely with libjvm.so]
def register_unwinder():
    unwinder = None
    if _have_unwinder:
        unwinder = OpenJDKUnwinder()
        gdb.unwinder.register_unwinder(None, unwinder, replace=True)
    filt = OpenJDKFrameFilter(unwinder)
    gdb.frame_filters[filt.name] = filt

register_unwinder()
