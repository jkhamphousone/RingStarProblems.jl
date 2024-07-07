function distance(x1,x2)
	return floor(sqrt((x1[1]-x2[1])^2+(x1[2]-x2[2])^2)+0.5)
end

function ceil_labbe(x)
    ceil(Int,x)
end

function mima(a,b)
    min(a,b), max(a,b)
end

function choppre(fname)
  linetodelete = "</pre>\n"
  linelength = length(linetodelete)
  open(fname, "r+") do f
    readuntil(f, linetodelete)
    seek(f, position(f) - linelength)
    write(f, " "^linelength)
  end
end

function compute_hubs(x_opt, V)
    H = Int[1]
    current = 1
    next_one = true
    while next_one
        next_one = false
        for i in V
            if !(i in H)
                if i < current && x_opt[i,current] > .5
                    current = i
                    push!(H, current)
                    next_one = true
                elseif i > current && x_opt[current,i] > .5
                    current = i
                    push!(H, current)
                    next_one = true
                end
            end
        end
    end

    return H
end
