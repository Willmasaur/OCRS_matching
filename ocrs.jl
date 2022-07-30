using JuMP
using AmplNLWriter
using Couenne_jll

model = Model(() -> AmplNLWriter.Optimizer(Couenne_jll.amplexe))

n = 80
c = 0.3445
b = c/(1-c)

@variable(model, y[1:n] >= 0)
@variable(model, z[1:n] >= 0)
@variable(model, yTerm[1:n] >= 0)
@variable(model, zTerm[1:n] >= 0)
@variable(model, yExtra >= 0)
@variable(model, zExtra >= 0)
@variable(model, product >= 0)
@variable(model, obj >= 0)

@constraint(model, sum(y[i] for i in 1:n) <= 1)
@constraint(model, sum(z[i] for i in 1:n) <= 1)
for i in 1:n
    @constraint(model, y[i] + z[i] <= 1)
    @NLconstraint(model, yTerm[i] == b*y[i]*(1-b/(1+b*y[i]))/prod(1+b*y[j] for j in 1:i-1))
    @NLconstraint(model, zTerm[i] == b*z[i]*(1-b/(1+b*z[i]))/prod(1+b*z[j] for j in 1:i-1))
end
@NLconstraint(model, yExtra == (1-b)/b*prod(1-b*y[i] for i in 1:n)*(1-exp(-b*(1-sum(y[i] for i in 1:n)))))
@NLconstraint(model, zExtra == (1-b)/b*prod(1-b*z[i] for i in 1:n)*(1-exp(-b*(1-sum(z[i] for i in 1:n)))))
@NLconstraint(model, product == (sum(yTerm[i] for i in 1:n)+yExtra)*(sum(zTerm[i] for i in 1:n)+zExtra))
@NLconstraint(model, obj == 1-3*c+product-sum(yTerm[i]*zTerm[i] for i in 1:n)-b^2*(1-b)^2/n)

@objective(model, Min, obj)
status = optimize!(model)

println(value.(y))
println(value.(z))

println("", "Objective value is ", objective_value(model))
