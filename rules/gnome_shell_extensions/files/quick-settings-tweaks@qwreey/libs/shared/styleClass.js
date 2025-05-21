// Re-layout & painting only once
// We use StyleClass instead of add_style_class_name in this extension
export class StyleClass {
    constructor(classString) {
        this.modified = false;
        this.classArray = classString.split(" ");
    }
    remove(className) {
        const lastLen = this.classArray.length;
        this.classArray = this.classArray.filter(i => i != className);
        if (this.classArray.length != lastLen) {
            this.modified = true;
        }
        return this;
    }
    add(className) {
        if (this.classArray.includes(className))
            return this;
        this.classArray.push(className);
        this.modified = true;
        return this;
    }
    stringify() {
        return this.classArray.join(" ");
    }
}
