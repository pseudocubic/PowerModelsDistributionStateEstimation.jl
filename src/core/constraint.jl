"""
    constraint_mc_residual for exact power flow equations
"""
function constraint_mc_residual(pm::_PMs.AbstractPowerModel, i::Int;
                                nw::Int=pm.cnw)

    res = _PMD.var(pm, nw, :res, i)
    cmp_id = _PMs.ref(pm, nw, :meas, i, "cmp_id")
    _PMD.ref(pm, nw, :meas, i, "cmp") == :branch ? id = (cmp_id, _PMD.ref(pm,nw,:branch, cmp_id)["f_bus"], _PMD.ref(pm,nw,:branch,cmp_id)["t_bus"]) : id = _PMs.ref(pm, nw, :meas, i, "cmp_id")
    var = _PMs.var(pm, nw, _PMs.ref(pm, nw, :meas, i, "var"), id)
    dst = _PMD.ref(pm, nw, :meas, i, "dst")
    rsc = _PMD.ref(pm, nw, :setting)["weight_rescaler"]
    nph = 3
    for c in _PMD.conductor_ids(pm; nw=nw)
        if typeof(dst[c]) == Float64
            JuMP.@constraint(pm.model,
                var[c] == dst[c]
            )
            JuMP.@constraint(pm.model,
                res[c] == 0.0
            )
        elseif typeof(dst[c]) == _DST.Normal{Float64}
            if _PMD.ref(pm, nw, :setting)["estimation_criterion"] == "wls"
                JuMP.@constraint(pm.model,
                    res[c] == (var[c]-_DST.mean(dst[c]))^2/(_DST.std(dst[c])*rsc)^2
                )
            elseif _PMD.ref(pm, nw, :setting)["estimation_criterion"] == "wlav"
                JuMP.@constraint(pm.model,
                    res[c] >= (var[c]-_DST.mean(dst[c]))/(_DST.std(dst[c])*rsc)
                )
                JuMP.@constraint(pm.model,
                    res[c] >= -(var[c]-_DST.mean(dst[c]))/(_DST.std(dst[c])*rsc)
                )
            end
        else
            @warn "Currently, only Gaussian distributions are supported."
            # JuMP.set_lower_bound(var[c],_DST.minimum(dst[c]))
            # JuMP.set_upper_bound(var[c],_DST.maximum(dst[c]))
            # dst(x) = -_DST.logpdf(dst[c],x)
            # grd(x) = -_DST.gradlogpdf(dst[c],x)
            # hes(x) = -_DST.heslogpdf(dst[c],x) # doesn't exist yet
            # register(pm.model,Symbol("df_$(i)_$(c)"),1,dst,grd,hes)
            # Expr(:call, :myf, [x[i] for i=1:n]...)
            # https://stackoverflow.com/questions/44710900/juliajump-variable-number-of-arguments-to-function
            # JuMP.@NLconstraint(pm.model,
            #     res[c] == Expr(:call, Symbol("df_$(i)_$(c)"), var[c]
            # )
        end
    end
end

function constraint_mc_residual(pm::_PMD.SDPUBFPowerModel, i::Int;
                                nw::Int=pm.cnw)

    res = _PMD.var(pm, nw, :res, i)
    cmp_id = _PMs.ref(pm, nw, :meas, i, "cmp_id")
    _PMD.ref(pm, nw, :meas, i, "cmp") == :branch ? id = (cmp_id, _PMD.ref(pm,nw,:branch, cmp_id)["f_bus"], _PMD.ref(pm,nw,:branch,cmp_id)["t_bus"]) : id = _PMs.ref(pm, nw, :meas, i, "cmp_id")
    var = _PMs.var(pm, nw, _PMs.ref(pm, nw, :meas, i, "var"), id)
    dst = _PMD.ref(pm, nw, :meas, i, "dst")
    rsc = _PMD.ref(pm, nw, :setting)["weight_rescaler"]
    nph = 3
    for c in _PMD.conductor_ids(pm; nw=nw)
        if typeof(dst[c]) == Float64
            JuMP.@constraint(pm.model,
                var[c] == dst[c]
            )
            JuMP.@constraint(pm.model,
                res[c] == 0.0
            )
        elseif typeof(dst[c]) == _DST.Normal{Float64}
            if _PMD.ref(pm, nw, :setting)["estimation_criterion"] == "wls"
                JuMP.@constraint(pm.model,
                    res[c] >= 0.0002*(var[c]-_DST.mean(dst[c]))^2/(_DST.std(dst[c])*rsc)^2
                )

            elseif _PMD.ref(pm, nw, :setting)["estimation_criterion"] == "wlav"
                JuMP.@constraint(pm.model,
                    res[c] >= (var[c]-_DST.mean(dst[c]))/(_DST.std(dst[c])*rsc)
                )
                JuMP.@constraint(pm.model,
                    res[c] >= -(var[c]-_DST.mean(dst[c]))/(_DST.std(dst[c])*rsc)
                )
            end
        else
            @warn "Currently, only Gaussian distributions are supported."
            # JuMP.set_lower_bound(var[c],_DST.minimum(dst[c]))
            # JuMP.set_upper_bound(var[c],_DST.maximum(dst[c]))
            # dst(x) = -_DST.logpdf(dst[c],x)
            # grd(x) = -_DST.gradlogpdf(dst[c],x)
            # hes(x) = -_DST.heslogpdf(dst[c],x) # doesn't exist yet
            # register(pm.model,Symbol("df_$(i)_$(c)"),1,dst,grd,hes)
            # Expr(:call, :myf, [x[i] for i=1:n]...)
            # https://stackoverflow.com/questions/44710900/juliajump-variable-number-of-arguments-to-function
            # JuMP.@NLconstraint(pm.model,
            #     res[c] == Expr(:call, Symbol("df_$(i)_$(c)"), var[c]
            # )
        end
    end
end
