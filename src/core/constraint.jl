""
#TODO:deprecated?
function constraint_mc_load(pm::_PMs.AbstractPowerModel, i::Int;
                            nw::Int=pm.cnw, report::Bool=true)
    _PMs.var(pm, nw, :pd_bus)[i] = _PMs.var(pm, nw, :pd, i)
    _PMs.var(pm, nw, :qd_bus)[i] = _PMs.var(pm, nw, :qd, i)

    if report
        _PMs.sol(pm, nw, :load, i)[:pd_bus] = _PMs.var(pm, nw, :pd_bus, i)
        _PMs.sol(pm, nw, :load, i)[:qd_bus] = _PMs.var(pm, nw, :qd_bus, i)
    end
end


"""
    constraint_mc_residual
"""
function constraint_mc_residual(pm::_PMs.AbstractPowerModel, i::Int;
                                nw::Int=pm.cnw)

    display(i)
    res = _PMD.var(pm, nw, :res, i)
    display(res)
    var = _PMD.var(pm, nw, _PMD.ref(pm, nw, :meas, i, "var"),
                           _PMD.ref(pm, nw, :meas, i, "cmp_id"))
    display(var)
    dst = _PMD.ref(pm, nw, :meas, i, "dst")
    display(dst)

    for c in _PMs.conductor_ids(pm; nw=nw)
        if typeof(dst[c]) == Float64
            JuMP.@constraint(pm.model,
                var[c] == dst[c]
            )
            JuMP.@constraint(pm.model,
                res[c] == 0.0
            )
        elseif typeof(dst[c]) == _DST.Normal{Float64}
            if pm.setting["estimation_criterion"] == "wls"
                JuMP.@constraint(pm.model,
                    res[c] == (var[c]-_DST.mean(dst[c]))^2/_DST.var(dst[c])^2
                )
            elseif pm.setting["estimation_criterion"] == "wlav"
                JuMP.@constraint(pm.model,
                    res[c] >= (var[c]-_DST.mean(dst[c]))/_DST.var(dst[c])
                )
                JuMP.@constraint(pm.model,
                    res[c] >= -(var[c]-_DST.mean(dst[c]))/_DST.var(dst[c])
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
