// Connection destroyer
class Maid {
    constructor() {
        this.records = [];
    }
    connectJob(signalObject, signalName, handleFunc, priority = 0) {
        const id = signalObject.connect(signalName, handleFunc);
        this.getRecords().push([Maid.TaskType.Connect, priority, signalObject, id]);
        return id;
    }
    functionJob(func, priority = 0) {
        this.getRecords().push([Maid.TaskType.Function, priority, func]);
    }
    disposeJob(object, priority = 0) {
        this.getRecords().push([Maid.TaskType.Dispose, priority, object]);
        return object;
    }
    runDisposeJob(object, priority = 0) {
        this.getRecords().push([Maid.TaskType.RunDispose, priority, object]);
        return object;
    }
    destroyJob(object, priority = 0) {
        this.getRecords().push([Maid.TaskType.Destroy, priority, object]);
        return object;
    }
    destroy() {
        this.clear();
        this.records = null;
    }
    getRecords() {
        if (!this.records)
            Error("Maid object already destroyed");
        return this.records;
    }
    patchJob(patchObject, patchName, handleFunc, priority = 0) {
        // Check if patchObject is defined before accessing its properties
        if (!patchObject) {
            console.error('Maid.patchJob: patchObject is undefined');
            return;
        }
        const original = patchObject[patchName];
        this.getRecords().push([Maid.TaskType.Patch, priority, patchObject, patchName, original]);
        patchObject[patchName] = handleFunc(original);
    }
    // [ patchObject, connection, original, undo? ]
    hideJob(patchObject, undo, priority = 0) {
        // Check if patchObject is defined
        if (!patchObject) {
            console.error('Maid.hideJob: patchObject is undefined');
            return;
        }
        const original = patchObject.visible;
        const connection = patchObject.connect("show", () => {
            patchObject.hide();
        });
        patchObject.hide();
        this.getRecords().push([Maid.TaskType.Hide, priority, patchObject, connection, original, undo]);
    }
    clear() {
        const records = this.getRecords();
        records.sort((a, b) => b[1] - a[1]);
        for (const record of records) {
            switch (record[0]) {
                case Maid.TaskType.Connect:
                    record[2].disconnect(record[3]);
                    break;
                case Maid.TaskType.Function:
                    record[2]();
                    break;
                case Maid.TaskType.Dispose:
                    record[2].dispose();
                    break;
                case Maid.TaskType.RunDispose:
                    record[2].run_dispose();
                    break;
                case Maid.TaskType.Destroy:
                    record[2].destroy();
                    break;
                case Maid.TaskType.Patch:
                    // Check if patchObject (record[2]) is defined
                    if (record[2]) {
                        record[2][record[3]] = record[4];
                    }
                    break;
                case Maid.TaskType.Hide:
                    {
                        const patchObject = record[2];
                        // Check if patchObject is defined before using it
                        if (!patchObject)
                            break;
                        const original = record[4];
                        const undo = record[5];
                        patchObject.disconnect(record[3]);
                        if (undo) {
                            const result = undo(original, patchObject);
                            if (result === true) {
                                patchObject.show();
                            }
                        }
                        else {
                            if (original)
                                patchObject.show();
                        }
                    }
                    break;
                default:
                    throw Error("Unknown task type.");
            }
        }
        this.records = [];
    }
}
(function (Maid) {
    let TaskType;
    (function (TaskType) {
        TaskType[TaskType["Connect"] = 0] = "Connect";
        TaskType[TaskType["Function"] = 1] = "Function";
        TaskType[TaskType["Dispose"] = 2] = "Dispose";
        TaskType[TaskType["RunDispose"] = 3] = "RunDispose";
        TaskType[TaskType["Destroy"] = 4] = "Destroy";
        TaskType[TaskType["Patch"] = 5] = "Patch";
        TaskType[TaskType["Hide"] = 6] = "Hide";
    })(TaskType = Maid.TaskType || (Maid.TaskType = {}));
    Maid.Priority = {
        High: 2000,
        Default: 0,
        Low: -2000,
    };
})(Maid || (Maid = {}));
export default Maid;
