
module TFTP

  # http://tools.ietf.org/html/rfc1350#section-5
  module Opcode
    RRQ = 1
    WRQ = 2
    DATA = 3
    ACK = 4
    ERROR = 5
    OACK = 6
  end

  # http://tools.ietf.org/html/rfc1350#page-10
  module ErrorCode
    NOT_DEFINED = 0
    NOT_FOUND = 1
    ACCESS_VIOLATION = 2
    DISK_FULL = 3
    ILLEGAL_TFTP_OPERATION = 4
    UNKNOWN_TRANSFER_ID = 5
    FILE_ALREADY_EXISTS = 6
    NO_SUCH_USER = 7
  end

  ERROR_DESCRIPTIONS = {
    ErrorCode::NOT_FOUND => "File not found.",
    ErrorCode::ACCESS_VIOLATION => "Access violation.",
    ErrorCode::DISK_FULL => "Disk full or allocation exceeded.",
    ErrorCode::ILLEGAL_TFTP_OPERATION => "Illegal TFTP operation.",
    ErrorCode::UNKNOWN_TRANSFER_ID => "Unknown transfer ID.",
    ErrorCode::FILE_ALREADY_EXISTS => "File already exists.",
    ErrorCode::NO_SUCH_USER => "No such user."
  }


end
