using JuMP, Gurobi, Test, Random

function test()
    model = Model(Gurobi.Optimizer)
    @variable(model, x <= 10.5, Int)
    @variable(model, y <= 0.5, Int)
    @objective(model, Max, x+y)
    function my_callback_function(cb_data)
        x_val = callback_value(cb_data, x)
        status = MOI.submit(
            model, MOI.HeuristicSolution(cb_data), [x], [floor(Int, x_val)]
        )
        println("I submitted a heuristic solution, and the status was: ", status)
    end
    MOI.set(model, MOI.HeuristicCallback(), my_callback_function)
    optimize!(model)
end

test()
