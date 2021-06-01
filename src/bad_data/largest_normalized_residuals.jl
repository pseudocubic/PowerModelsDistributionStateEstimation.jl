"""
    simple_normalized_residuals(data::Dict, se_sol::Dict, state_estimation_type::String; rescaler::Float64=1.0)
It normalizes the residuals only based on their standard deviation, no sensitivity matrix involved.
Avoids all the matrix calculations but is relatively rudimental
"""
function simple_normalized_residuals(data::Dict, se_sol::Dict, state_estimation_type::String; rescaler::Float64=1.0)
    if occursin(state_estimation_type, "wls")
        p = 2
    elseif occursin(state_estimation_type, "wlav")
        p=1
    else
        error("This method works only with (r)wls and (r)wlav state estimation")
    end
    for (m, meas) in se_sol["solution"]["meas"]
        meas["norm_res"] = meas["res"].*_DST.std.(data["meas"][m]["dst"]).^p*rescaler
    end
end

