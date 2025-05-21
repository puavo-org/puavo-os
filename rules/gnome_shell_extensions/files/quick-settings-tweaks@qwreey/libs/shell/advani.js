import Clutter from "gi://Clutter";
import Graphene from "gi://Graphene";
export class ModeDefine {
    constructor(params) {
        for (const [key, value] of Object.entries(params)) {
            this[key] = value;
        }
    }
}
// Utility functions
export function createBezier(x1, y1, x2, y2) {
    return [
        new Graphene.Point({ x: x1, y: y1 }),
        new Graphene.Point({ x: x2, y: y2 })
    ];
}
// Template AdvAni animations
export var AdvAnimationMode;
(function (AdvAnimationMode) {
    AdvAnimationMode[AdvAnimationMode["LowBackover"] = 2000] = "LowBackover";
    AdvAnimationMode[AdvAnimationMode["MiddleBackover"] = 2001] = "MiddleBackover";
})(AdvAnimationMode || (AdvAnimationMode = {}));
export const AdvAnimationModeDefines = [
    new ModeDefine({
        mode: Clutter.AnimationMode.CUBIC_BEZIER,
        getCubicBezierProgress: () => createBezier(.225, 1.2, .45, 1)
    }),
    new ModeDefine({
        mode: Clutter.AnimationMode.CUBIC_BEZIER,
        getCubicBezierProgress: () => createBezier(.4, 1.35, .55, 1)
    }),
];
// Main AdvAni ease function
export function ease(actor, params) {
    // Get mode defines
    let modeDefine;
    if (params.mode && params.mode > Clutter.AnimationMode.ANIMATION_LAST) {
        modeDefine = AdvAnimationModeDefines[params.mode - AdvAnimationMode.LowBackover];
        params.mode = modeDefine.mode;
    }
    else if ((typeof params.mode == "object") && (params.mode instanceof ModeDefine)) {
        modeDefine = params.mode;
        params.mode = modeDefine.mode;
    }
    // Run gnome ease function
    actor.ease(params);
    if (!modeDefine)
        return;
    // Adjust bezier progress if option exist
    let { getCubicBezierProgress, cubicBezierProgress } = modeDefine;
    if (getCubicBezierProgress)
        cubicBezierProgress = getCubicBezierProgress();
    if (cubicBezierProgress) {
        for (const key in params) {
            const transition = actor.get_transition(key.replace(/_/g, '-'));
            if (!transition)
                continue;
            transition.set_cubic_bezier_progress(...cubicBezierProgress);
        }
    }
}
