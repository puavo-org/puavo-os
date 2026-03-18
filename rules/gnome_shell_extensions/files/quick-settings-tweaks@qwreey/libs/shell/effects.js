import GObject from 'gi://GObject';
import Shell from 'gi://Shell';
import Cogl from 'gi://Cogl';
import Global from '../../global.js';
// #region RoundClipEffect
export class RoundClipEffect extends Shell.GLSLEffect {
    static { this.uniforms = null; }
    vfunc_build_pipeline() {
        const [declarations, code] = Global.GetShader("media/rounded_corners.frag");
        this.add_glsl_snippet(
        // FIXME: waitting for type definition update
        Cogl.SnippetHook.FRAGMENT, declarations, code, false);
    }
    vfunc_paint_target(node, ctx) {
        // Reset to default blend string.
        this.get_pipeline()?.set_blend('RGBA = ADD(SRC_COLOR, DST_COLOR*(1-SRC_COLOR[A]))');
        super.vfunc_paint_target(node, ctx);
    }
    updateUniforms(scale_factor, corners_cfg, outer_bounds, border, pixel_step) {
        const border_width = (border?.width ?? 0) * scale_factor;
        const border_color = border?.color ?? [0, 0, 0, 0];
        const outer_radius = corners_cfg.border_radius * scale_factor;
        const { padding, smoothing } = corners_cfg;
        const bounds = [
            outer_bounds.x1 + (padding ? (padding.left * scale_factor) : 0),
            outer_bounds.y1 + (padding ? (padding.top * scale_factor) : 0),
            outer_bounds.x2 - (padding ? (padding.right * scale_factor) : 0),
            outer_bounds.y2 - (padding ? (padding.bottom * scale_factor) : 0),
        ];
        const inner_bounds = [
            bounds[0] + border_width,
            bounds[1] + border_width,
            bounds[2] - border_width,
            bounds[3] - border_width,
        ];
        let inner_radius = outer_radius - border_width;
        if (inner_radius < 0.001) {
            inner_radius = 0.0;
        }
        if (!pixel_step) {
            const actor = this.actor;
            pixel_step = [1 / actor.get_width(), 1 / actor.get_height()];
        }
        // Setup with squircle shape
        let exponent = smoothing * 10.0 + 2.0;
        let radius = outer_radius * 0.5 * exponent;
        const max_radius = Math.min(bounds[3] - bounds[0], bounds[4] - bounds[1]);
        if (radius > max_radius) {
            exponent *= max_radius / radius;
            radius = max_radius;
        }
        inner_radius *= radius / outer_radius;
        const location = this.getLocation();
        this.set_uniform_float(location.bounds, 4, bounds);
        this.set_uniform_float(location.inner_bounds, 4, inner_bounds);
        this.set_uniform_float(location.pixel_step, 2, pixel_step);
        this.set_uniform_float(location.border_width, 1, [border_width]);
        this.set_uniform_float(location.exponent, 1, [exponent]);
        this.set_uniform_float(location.clip_radius, 1, [radius]);
        this.set_uniform_float(location.border_color, 4, border_color);
        this.set_uniform_float(location.inner_clip_radius, 1, [inner_radius]);
        this.queue_repaint();
    }
    getLocation() {
        let location = RoundClipEffect.uniforms;
        if (!location) {
            location = new RoundClipEffect.Uniforms();
            for (const key in location) {
                location[key] = this.get_uniform_location(key);
            }
            RoundClipEffect.uniforms = location;
        }
        return location;
    }
}
GObject.registerClass(RoundClipEffect);
(function (RoundClipEffect) {
    // Uniform location cache
    class Uniforms {
        constructor() {
            this.bounds = 0;
            this.clip_radius = 0;
            this.exponent = 0;
            this.inner_bounds = 0;
            this.inner_clip_radius = 0;
            this.pixel_step = 0;
            this.border_width = 0;
            this.border_color = 0;
        }
    }
    RoundClipEffect.Uniforms = Uniforms;
})(RoundClipEffect || (RoundClipEffect = {}));
// #endregion RoundClipEffect
