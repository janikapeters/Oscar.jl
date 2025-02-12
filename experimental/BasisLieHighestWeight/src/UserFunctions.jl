@doc raw"""
    basis_lie_highest_weight_operators(type::Symbol, rank::Int)

Lists the operators available for a given simple Lie algebra of type `type_rank`,
together with their index.
Operators $f_\alpha$ of negative roots are shown as the coefficients of the corresponding positive root.
w.r.t. the simple roots $\alpha_i$.

# Examples
```jldoctest
julia> basis_lie_highest_weight_operators(:B, 2)
4-element Vector{Tuple{Int64, Vector{QQFieldElem}}}:
 (1, [1, 0])
 (2, [0, 1])
 (3, [1, 1])
 (4, [1, 2])
```
"""
function basis_lie_highest_weight_operators(type::Symbol, rank::Int)
  R = root_system(type, rank)
  return collect(enumerate(map(r -> Oscar._vec(coefficients(r)), positive_roots(R)))) # TODO: clean up
end

@doc raw"""
    basis_lie_highest_weight(type::Symbol, rank::Int, highest_weight::Vector{Int}; monomial_ordering::Symbol=:degrevlex)
    basis_lie_highest_weight(type::Symbol, rank::Int, highest_weight::Vector{Int}, birational_sequence::Vector{Int}; monomial_ordering::Symbol=:degrevlex)
    basis_lie_highest_weight(type::Symbol, rank::Int, highest_weight::Vector{Int}, birational_sequence::Vector{Vector{Int}}; monomial_ordering::Symbol=:degrevlex)

Computes a monomial basis for the highest weight module with highest weight
`highest_weight` (in terms of the fundamental weights $\omega_i$),
for a simple Lie algebra of type `type_rank`.

If no birational sequence is specified, all operators in the order of `basis_lie_highest_weight_operators` are used.
A birational sequence of type `Vector{Int}` is a sequence of indices of operators in `basis_lie_highest_weight_operators`.
A birational sequence of type `Vector{Vector{Int}}` is a sequence of weights in terms of the simple roots $\alpha_i$.

`monomial_ordering` describes the monomial ordering used for the basis.
If this is a weighted ordering, the height of the corresponding root is used as weight.

# Examples
```jldoctest
julia> base = basis_lie_highest_weight(:A, 2, [1, 1])
Monomial basis of a highest weight module
  of highest weight [1, 1]
  of dimension 8
  with monomial ordering degrevlex([x1, x2, x3])
over Lie algebra of type A2
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [1, 0]
    [0, 1]
    [1, 1]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0]
    [0, 1]

julia> base = basis_lie_highest_weight(:A, 3, [2, 2, 3]; monomial_ordering = :lex)
Monomial basis of a highest weight module
  of highest weight [2, 2, 3]
  of dimension 1260
  with monomial ordering lex([x1, x2, x3, x4, x5, x6])
over Lie algebra of type A3
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [1, 0, 0]
    [0, 1, 0]
    [0, 0, 1]
    [1, 1, 0]
    [0, 1, 1]
    [1, 1, 1]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0, 0]
    [0, 1, 0]
    [0, 0, 1]

julia> base = basis_lie_highest_weight(:A, 2, [1, 0], [1,2,1])
Monomial basis of a highest weight module
  of highest weight [1, 0]
  of dimension 3
  with monomial ordering degrevlex([x1, x2, x3])
over Lie algebra of type A2
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [1, 0]
    [0, 1]
    [1, 0]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0]

julia> base = basis_lie_highest_weight(:A, 2, [1, 0], [[1,0], [0,1], [1,0]])
Monomial basis of a highest weight module
  of highest weight [1, 0]
  of dimension 3
  with monomial ordering degrevlex([x1, x2, x3])
over Lie algebra of type A2
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [1, 0]
    [0, 1]
    [1, 0]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0]

julia> base = basis_lie_highest_weight(:C, 3, [1, 1, 1]; monomial_ordering = :lex)
Monomial basis of a highest weight module
  of highest weight [1, 1, 1]
  of dimension 512
  with monomial ordering lex([x1, x2, x3, x4, x5, x6, x7, x8, x9])
over Lie algebra of type C3
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [1, 0, 0]
    [0, 1, 0]
    [0, 0, 1]
    [1, 1, 0]
    [0, 1, 1]
    [0, 2, 1]
    [1, 1, 1]
    [1, 2, 1]
    [2, 2, 1]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0, 0]
    [0, 1, 0]
    [0, 0, 1]
    [0, 1, 1]
    [1, 1, 1]
```
"""
function basis_lie_highest_weight(
  type::Symbol, rank::Int, highest_weight::Vector{Int}; monomial_ordering::Symbol=:degrevlex
)
  L = lie_algebra(QQ, type, rank)
  V = SimpleModuleData(L, WeightLatticeElem(root_system(L), highest_weight))
  operators = operators_asc_height(L)
  return basis_lie_highest_weight_compute(V, operators, monomial_ordering)
end

function basis_lie_highest_weight(
  type::Symbol,
  rank::Int,
  highest_weight::Vector{Int},
  birational_sequence::Vector{Int};
  monomial_ordering::Symbol=:degrevlex,
)
  L = lie_algebra(QQ, type, rank)
  V = SimpleModuleData(L, WeightLatticeElem(root_system(L), highest_weight))
  operators = operators_by_index(L, birational_sequence)
  return basis_lie_highest_weight_compute(V, operators, monomial_ordering)
end

function basis_lie_highest_weight(
  type::Symbol,
  rank::Int,
  highest_weight::Vector{Int},
  birational_sequence::Vector{Vector{Int}};
  monomial_ordering::Symbol=:degrevlex,
)
  L = lie_algebra(QQ, type, rank)
  V = SimpleModuleData(L, WeightLatticeElem(root_system(L), highest_weight))
  operators = operators_by_simple_roots(L, birational_sequence)
  return basis_lie_highest_weight_compute(V, operators, monomial_ordering)
end

@doc raw"""
    basis_lie_highest_weight_lusztig(type::Symbol, rank::Int, highest_weight::Vector{Int}, reduced_expression::Vector{Int})

Computes a monomial basis for the highest weight module with highest weight
`highest_weight` (in terms of the fundamental weights $\omega_i$),
for a simple Lie algebra $L$ of type `type_rank`.

Let $\omega_0 = s_{i_1} \cdots s_{i_N}$ be a reduced expression of the longest element in the Weyl group of $L$
given as indices $[i_1, \dots, i_N]$ in `reduced_expression`.
Then the birational sequence used consists of $\beta_1, \dots, \beta_N$ where $\beta_1 := \alpha_{i_1}$ and \beta_k := \alpha_{i_k} s_{i_{k-1}} \cdots s_{i_1}$ for $k = 2, \dots, N$.

The monomial ordering is fixed to `wdegrevlex` (weighted degree reverse lexicographic order).

# Examples
```jldoctest
julia> base = basis_lie_highest_weight_lusztig(:D, 4, [1,1,1,1], [4,3,2,4,3,2,1,2,4,3,2,1])
Monomial basis of a highest weight module
  of highest weight [1, 1, 1, 1]
  of dimension 4096
  with monomial ordering wdegrevlex([x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12], [1, 1, 3, 2, 2, 1, 5, 4, 3, 3, 2, 1])
over Lie algebra of type D4
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [0, 0, 0, 1]
    [0, 0, 1, 0]
    [0, 1, 1, 1]
    [0, 1, 1, 0]
    [0, 1, 0, 1]
    [0, 1, 0, 0]
    [1, 2, 1, 1]
    [1, 1, 1, 1]
    [1, 1, 0, 1]
    [1, 1, 1, 0]
    [1, 1, 0, 0]
    [1, 0, 0, 0]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0, 0, 0]
    [0, 1, 0, 0]
    [0, 0, 1, 0]
    [0, 0, 0, 1]
    [0, 0, 1, 1]
```
"""
function basis_lie_highest_weight_lusztig(
  type::Symbol, rank::Int, highest_weight::Vector{Int}, reduced_expression::Vector{Int}
)
  monomial_ordering = :wdegrevlex
  L = lie_algebra(QQ, type, rank)
  V = SimpleModuleData(L, WeightLatticeElem(root_system(L), highest_weight))
  operators = operators_lusztig(L, reduced_expression)
  return basis_lie_highest_weight_compute(V, operators, monomial_ordering)
end

@doc raw"""
    basis_lie_highest_weight_string(type::Symbol, rank::Int, highest_weight::Vector{Int}, reduced_expression::Vector{Int})

Computes a monomial basis for the highest weight module with highest weight
`highest_weight` (in terms of the fundamental weights $\omega_i$),
for a simple Lie algebra $L$ of type `type_rank`.

Let $\omega_0 = s_{i_1} \cdots s_{i_N}$ be a reduced expression of the longest element in the Weyl group of $L$
given as indices $[i_1, \dots, i_N]$ in `reduced_expression`.
Then the birational sequence used consists of $\alpha_{i_1}, \dots, \alpha_{i_N}$.

The monomial ordering is fixed to `neglex` (negative lexicographic order).      

# Examples
```jldoctest
julia> basis_lie_highest_weight_string(:B, 3, [1,1,1], [3,2,3,2,1,2,3,2,1])
Monomial basis of a highest weight module
  of highest weight [1, 1, 1]
  of dimension 512
  with monomial ordering neglex([x1, x2, x3, x4, x5, x6, x7, x8, x9])
over Lie algebra of type B3
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [0, 0, 1]
    [0, 1, 0]
    [0, 0, 1]
    [0, 1, 0]
    [1, 0, 0]
    [0, 1, 0]
    [0, 0, 1]
    [0, 1, 0]
    [1, 0, 0]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0, 0]
    [0, 1, 0]
    [0, 0, 1]

julia> basis_lie_highest_weight_string(:A, 4, [1,1,1,1], [4,3,2,1,2,3,4,3,2,3])
Monomial basis of a highest weight module
  of highest weight [1, 1, 1, 1]
  of dimension 1024
  with monomial ordering neglex([x1, x2, x3, x4, x5, x6, x7, x8, x9, x10])
over Lie algebra of type A4
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [0, 0, 0, 1]
    [0, 0, 1, 0]
    [0, 1, 0, 0]
    [1, 0, 0, 0]
    [0, 1, 0, 0]
    [0, 0, 1, 0]
    [0, 0, 0, 1]
    [0, 0, 1, 0]
    [0, 1, 0, 0]
    [0, 0, 1, 0]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0, 0, 0]
    [0, 1, 0, 0]
    [0, 0, 1, 0]
    [0, 0, 0, 1]
    [0, 1, 0, 1]
```
"""
function basis_lie_highest_weight_string(
  type::Symbol, rank::Int, highest_weight::Vector{Int}, reduced_expression::Vector{Int}
)
  monomial_ordering = :neglex
  L = lie_algebra(QQ, type, rank)
  V = SimpleModuleData(L, WeightLatticeElem(root_system(L), highest_weight))
  operators = operators_by_index(L, reduced_expression)
  return basis_lie_highest_weight_compute(V, operators, monomial_ordering)
end

@doc raw"""
    basis_lie_highest_weight_ffl(type::Symbol, rank::Int, highest_weight::Vector{Int})

Computes a monomial basis for the highest weight module with highest weight
`highest_weight` (in terms of the fundamental weights $\omega_i$),
for a simple Lie algebra $L$ of type `type_rank`.

Then the birational sequence used consists of all operators in descening height of the corresponding root.

The monomial ordering is fixed to `degrevlex`.      
      
# Examples
```jldoctest
julia> basis_lie_highest_weight_ffl(:A, 3, [1,1,1])
Monomial basis of a highest weight module
  of highest weight [1, 1, 1]
  of dimension 64
  with monomial ordering degrevlex([x1, x2, x3, x4, x5, x6])
over Lie algebra of type A3
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [1, 1, 1]
    [0, 1, 1]
    [1, 1, 0]
    [0, 0, 1]
    [0, 1, 0]
    [1, 0, 0]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0, 0]
    [0, 1, 0]
    [0, 0, 1]
```
"""
function basis_lie_highest_weight_ffl(type::Symbol, rank::Int, highest_weight::Vector{Int})
  monomial_ordering = :degrevlex
  L = lie_algebra(QQ, type, rank)
  V = SimpleModuleData(L, WeightLatticeElem(root_system(L), highest_weight))
  operators = reverse(operators_asc_height(L))
  # we reverse the order here to have simple roots at the right end, this is then a good ordering.
  # simple roots at the right end speed up the program very much
  return basis_lie_highest_weight_compute(V, operators, monomial_ordering)
end

@doc raw"""
    basis_lie_highest_weight_nz(type::Symbol, rank::Int, highest_weight::Vector{Int}, reduced_expression::Vector{Int})

Computes a monomial basis for the highest weight module with highest weight
`highest_weight` (in terms of the fundamental weights $\omega_i$),
for a simple Lie algebra $L$ of type `type_rank`.

Let $\omega_0 = s_{i_1} \cdots s_{i_N}$ be a reduced expression of the longest element in the Weyl group of $L$
given as indices $[i_1, \dots, i_N]$ in `reduced_expression`.
Then the birational sequence used consists of $\alpha_{i_1}, \dots, \alpha_{i_N}$.

The monomial ordering is fixed to `degrevlex` (degree reverse lexicographic order).      

# Examples
```jldoctest
julia> basis_lie_highest_weight_nz(:C, 3, [1,1,1], [3,2,3,2,1,2,3,2,1])
Monomial basis of a highest weight module
  of highest weight [1, 1, 1]
  of dimension 512
  with monomial ordering degrevlex([x1, x2, x3, x4, x5, x6, x7, x8, x9])
over Lie algebra of type C3
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [0, 0, 1]
    [0, 1, 0]
    [0, 0, 1]
    [0, 1, 0]
    [1, 0, 0]
    [0, 1, 0]
    [0, 0, 1]
    [0, 1, 0]
    [1, 0, 0]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0, 0]
    [0, 1, 0]
    [0, 0, 1]

julia> basis_lie_highest_weight_nz(:A, 4, [1,1,1,1], [4,3,2,1,2,3,4,3,2,3])
Monomial basis of a highest weight module
  of highest weight [1, 1, 1, 1]
  of dimension 1024
  with monomial ordering degrevlex([x1, x2, x3, x4, x5, x6, x7, x8, x9, x10])
over Lie algebra of type A4
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [0, 0, 0, 1]
    [0, 0, 1, 0]
    [0, 1, 0, 0]
    [1, 0, 0, 0]
    [0, 1, 0, 0]
    [0, 0, 1, 0]
    [0, 0, 0, 1]
    [0, 0, 1, 0]
    [0, 1, 0, 0]
    [0, 0, 1, 0]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0, 0, 0]
    [0, 1, 0, 0]
    [0, 0, 1, 0]
    [0, 0, 0, 1]
    [0, 1, 0, 1] 
```
"""
function basis_lie_highest_weight_nz(
  type::Symbol, rank::Int, highest_weight::Vector{Int}, reduced_expression::Vector{Int}
)
  monomial_ordering = :degrevlex
  L = lie_algebra(QQ, type, rank)
  V = SimpleModuleData(L, WeightLatticeElem(root_system(L), highest_weight))
  operators = operators_by_index(L, reduced_expression)
  return basis_lie_highest_weight_compute(V, operators, monomial_ordering)
end

@doc raw"""
    basis_coordinate_ring_kodaira(type::Symbol, rank::Int, highest_weight::Vector{Int}, degree::Int; monomial_ordering::Symbol=:degrevlex)
    basis_coordinate_ring_kodaira(type::Symbol, rank::Int, highest_weight::Vector{Int}, degree::Int, birational_sequence::Vector{Int}; monomial_ordering::Symbol=:degrevlex)
    basis_coordinate_ring_kodaira(type::Symbol, rank::Int, highest_weight::Vector{Int}, degree::Int, birational_sequence::Vector{Vector{Int}}; monomial_ordering::Symbol=:degrevlex)

Compute monomial bases for the degree-truncated coordinate ring (for all degrees up to `degree`) 
of the Kodaira embedding of the generalized flag variety into the projective space of the highest weight module
with highest weight `highest_weight` for a simple Lie algebra $L$ of type `type` and rank `rank`.
Furthermore, for each degree, return the monomials that are not contained in the Minkowski sum
of the bases of the lower degrees.

!!! warning
    Currently, this function expects $-w_0(\lambda)$ instead of $\lambda$ as the `highest_weight` input.
    This might change in a minor release.
    
If no birational sequence is specified, all operators in the order of `basis_lie_highest_weight_operators` are used.
A birational sequence of type `Vector{Int}` is a sequence of indices of operators in `basis_lie_highest_weight_operators`.
A birational sequence of type `Vector{Vector{Int}}` is a sequence of weights in terms of the simple roots $\alpha_i$.

`monomial_ordering` describes the monomial ordering used for the basis.
If this is a weighted ordering, the height of the corresponding root is used as weight.

# Examples
```jldoctest
julia> mon_bases = basis_coordinate_ring_kodaira(:G, 2, [1,0], 6; monomial_ordering = :invlex)
6-element Vector{Tuple{MonomialBasis, Vector{ZZMPolyRingElem}}}:
 (Monomial basis of a highest weight module with highest weight [1, 0] over Lie algebra of type G2, [1, x1, x3, x1*x3, x1^2*x3, x3*x4, x1*x3*x4])
 (Monomial basis of a highest weight module with highest weight [2, 0] over Lie algebra of type G2, [x4, x1*x4, x4^2, x3*x4^2, x1*x3*x4^2])
 (Monomial basis of a highest weight module with highest weight [3, 0] over Lie algebra of type G2, [x1^2*x4^2, x4^3, x1*x4^3, x4^4, x1*x4^4, x3*x4^4, x5, x2*x5, x1*x2*x5, x1^2*x2*x5, x3^2*x5, x1*x3^2*x5, x3^3*x5, x1*x3^3*x5])
 (Monomial basis of a highest weight module with highest weight [4, 0] over Lie algebra of type G2, [x4^5, x1*x4^5, x4^6, x3^2*x4*x5, x1*x3^2*x4*x5, x3^2*x4^2*x5, x3^3*x4^2*x5])
 (Monomial basis of a highest weight module with highest weight [5, 0] over Lie algebra of type G2, [x1^2*x4^6, x4^7, x1*x4^7, x2*x4^3*x5, x1*x2*x4^3*x5, x2*x3*x4^3*x5, x1*x2*x3*x4^3*x5, x1^2*x2*x3*x4^3*x5, x2*x3^2*x4^3*x5, x1*x2*x3^2*x4^3*x5, x1^2*x2*x3^2*x4^3*x5, x2*x4^4*x5])
 (Monomial basis of a highest weight module with highest weight [6, 0] over Lie algebra of type G2, [x4^9, x1*x3*x4^4*x5, x2*x4^5*x5, x3*x4^5*x5, x3^2*x4^5*x5, x2*x3^2*x4^5*x5, x1*x2*x3^2*x4^5*x5, x3^4*x4*x5^2])

julia> [length(mon_basis[2]) for mon_basis in mon_bases]
6-element Vector{Int64}:
  7
  5
 14
  7
 12
  8

julia> mon_bases[end][1]
Monomial basis of a highest weight module
  of highest weight [6, 0]
  of dimension 714
  with monomial ordering invlex([x1, x2, x3, x4, x5, x6])
over Lie algebra of type G2
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [1, 0]
    [0, 1]
    [1, 1]
    [2, 1]
    [3, 1]
    [3, 2]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0]
    [2, 0]
    [3, 0]
    [4, 0]
    [5, 0]
    [6, 0]
```
"""
function basis_coordinate_ring_kodaira(
  type::Symbol,
  rank::Int,
  highest_weight::Vector{Int},
  degree::Int;
  monomial_ordering::Symbol=:degrevlex,
)
  L = lie_algebra(QQ, type, rank)
  operators = operators_asc_height(L)
  return basis_coordinate_ring_kodaira_compute(
    L, highest_weight, degree, operators, monomial_ordering
  )
end

function basis_coordinate_ring_kodaira(
  type::Symbol,
  rank::Int,
  highest_weight::Vector{Int},
  degree::Int,
  birational_sequence::Vector{Int};
  monomial_ordering::Symbol=:degrevlex,
)
  L = lie_algebra(QQ, type, rank)
  operators = operators_by_index(L, birational_sequence)
  return basis_coordinate_ring_kodaira_compute(
    L, highest_weight, degree, operators, monomial_ordering
  )
end

function basis_coordinate_ring_kodaira(
  type::Symbol,
  rank::Int,
  highest_weight::Vector{Int},
  degree::Int,
  birational_sequence::Vector{Vector{Int}};
  monomial_ordering::Symbol=:degrevlex,
)
  L = lie_algebra(QQ, type, rank)
  operators = operators_by_simple_roots(L, birational_sequence)
  return basis_coordinate_ring_kodaira_compute(
    L, highest_weight, degree, operators, monomial_ordering
  )
end

@doc raw"""
    basis_coordinate_ring_kodaira_ffl(type::Symbol, rank::Int, highest_weight::Vector{Int}, degree::Int; monomial_ordering::Symbol=:degrevlex)

Compute monomial bases for the degree-truncated coordinate ring (for all degrees up to `degree`) 
of the Kodaira embedding of the generalized flag variety into the projective space of the highest weight module
with highest weight `highest_weight` for a simple Lie algebra $L$ of type `type` and rank `rank`.
Furthermore, for each degree, return the monomials that are not contained in the Minkowski sum
of the bases of the lower degrees.

!!! warning
    Currently, this function expects $-w_0(\lambda)$ instead of $\lambda$ as the `highest_weight` input.
    This might change in a minor release.

The the birational sequence used consists of all operators in descening height of the corresponding root, i.e. a "good" ordering.

The monomial ordering is fixed to `degrevlex`. 

# Examples
```jldoctest
julia> mon_bases = basis_coordinate_ring_kodaira_ffl(:G, 2, [1,0], 6)
6-element Vector{Tuple{MonomialBasis, Vector{ZZMPolyRingElem}}}:
 (Monomial basis of a highest weight module with highest weight [1, 0] over Lie algebra of type G2, [1, x6, x4, x3, x2, x1, x1*x6])
 (Monomial basis of a highest weight module with highest weight [2, 0] over Lie algebra of type G2, [])
 (Monomial basis of a highest weight module with highest weight [3, 0] over Lie algebra of type G2, [])
 (Monomial basis of a highest weight module with highest weight [4, 0] over Lie algebra of type G2, [])
 (Monomial basis of a highest weight module with highest weight [5, 0] over Lie algebra of type G2, [])
 (Monomial basis of a highest weight module with highest weight [6, 0] over Lie algebra of type G2, [])

julia> [length(mon_basis[2]) for mon_basis in mon_bases]
6-element Vector{Int64}:
 7
 0
 0
 0
 0
 0

julia> mon_bases[end][1]
Monomial basis of a highest weight module
  of highest weight [6, 0]
  of dimension 714
  with monomial ordering degrevlex([x1, x2, x3, x4, x5, x6])
over Lie algebra of type G2
  where the used birational sequence consists of the following roots (given as coefficients w.r.t. alpha_i):
    [3, 2]
    [3, 1]
    [2, 1]
    [1, 1]
    [0, 1]
    [1, 0]
  and the basis was generated by Minkowski sums of the bases of the following highest weight modules:
    [1, 0]
```
"""
function basis_coordinate_ring_kodaira_ffl(
  type::Symbol, rank::Int, highest_weight::Vector{Int}, degree::Int
)
  monomial_ordering = :degrevlex
  L = lie_algebra(QQ, type, rank)
  operators = reverse(operators_asc_height(L))
  # we reverse the order here to have simple roots at the right end, this is then a good ordering.
  # simple roots at the right end speed up the program very much
  return basis_coordinate_ring_kodaira_compute(
    L, highest_weight, degree, operators, monomial_ordering
  )
end

function basis_lie_highest_weight_demazure(
  type::Symbol, rank::Int, highest_weight::Vector{Int}, weyl_group_elem::Vector{Int}; monomial_ordering::Symbol=:degrevlex
)
  L = lie_algebra(QQ, type, rank)
  w = WeylGroupElem(weyl_group(root_system(L)), weyl_group_elem)
  V = DemazureModuleData(L, WeightLatticeElem(root_system(L), highest_weight), w)
  operators = operators_asc_height(L) #TODO: write different operators function
  return basis_lie_highest_weight_compute(V, operators, monomial_ordering) 
end
