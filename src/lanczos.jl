import Base.LinAlg.BlasFloat

export eigvals_lanczos

function lanczos!{T}(K::KrylovSubspace{T})
    m = K.n
    αs = Array(T, m)
    βs = Array(T, m-1)
    for j=1:m-1
        w = nextvec(K)
        if j>1 w -= βs[j-1]*K.v[1] end
        w, y = orthogonalize(w, K, 1)
        αs[j] = y[1]
        βs[j] = convert(T, norm(w))
        append!(K, w/βs[j])
    end
    αs[m]= dot(nextvec(K), lastvec(K))
    SymTridiagonal(αs, βs)
end

function eigvals_lanczos(A, neigs::Int=size(A,1); tol::Real=size(A,1)^3*eps(), maxiter::Int=size(A,1))
    K = KrylovSubspace(A, 2) #In Lanczos, only remember the last two vectors
    eigvals_lanczos(K, neigs, tol, maxiter)
end

function eigvals_lanczos(A, n::Int, T::Type, neigs::Int=n; tol::Real=n^3*eps(), maxiter::Int=n)
    K = KrylovSubspace(A, n, 2, T) #In Lanczos, only remember the last two vectors
    eigvals_lanczos(K, neigs, tol, maxiter)
end

function eigvals_lanczos(K::KrylovSubspace{T}, neigs::Int; tol::Real=size(A,1)^3*eps(), maxiter::Int=size(A,1))
    initrand!(K)
    resnorms = zeros(maxiter)
    e1 = eigvals(lanczos!(K), 1:neigs)
    for iter=1:maxiter
        e0, e1 = e1, eigvals(lanczos!(K), 1:neigs)
        resnorms[iter] = norm(e1-e0)
        if resnorms[iter] < tol
            resnorms = resnorms[1:iter]
            break
        end
    end
    e1, ConvergenceHistory(0<=resnorms[end]<tol, tol, K.mvps, resnorms)
end

