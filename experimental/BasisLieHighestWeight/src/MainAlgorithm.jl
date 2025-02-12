function basis_lie_highest_weight_compute(
  V::ModuleData,
  operators::Vector{RootSpaceElem},     # monomial x_i is corresponds to f_operators[i]
  monomial_ordering_symb::Symbol,
)
  # Pseudocode:

  # basis_lie_highest_weight(highest_weight)
  #     return compute_monomials(highest_weight)

  # compute_monomials(highest_weight)
  #     if highest_weight was already computed 
  #         return old results
  #     if highest_weight = [0, ..., 0] or [0, ..., 1, ..., 0]
  #         return add_by_hand(highest_weight, {})
  #     else
  #         set_mon = {}
  #         go through all partitions lambda_1 + lambda_2 = highest_weight
  #             add compute_monomials(lambda_1) (+) compute_monomials(lambda_2) to set_mon 
  #         if set_mon too small
  #             add_by_hand(highest_weight, set_mon)
  #         return set_mon

  # add_by_hand(highest_weight, set_mon)
  #     add all monomials from set_mon to basis
  #     go through all weightspaces that are not full
  #         add_new_monomials(weightspace, set_mon)
  #     return set_mon

  # add_new_monomials(weightspace, set_mon)
  #     calculate monomials with weight in weightspace
  #     go through them one by one in monomial_ordering until basis is full
  #     return set_mon

  R = root_system(base_lie_algebra(V))
  
  birational_seq = birational_sequence(operators)

  ZZx, _ = polynomial_ring(ZZ, length(operators)) # for our monomials
  monomial_ordering = get_monomial_ordering(monomial_ordering_symb, ZZx, operators)

  # save computations from recursions
  calc_highest_weight = Dict{WeightLatticeElem,Set{ZZMPolyRingElem}}(
    zero(weight_lattice(R)) => Set([ZZx(1)])
  )
  # save all highest weights, for which the Minkowski-sum did not suffice to gain all monomials
  no_minkowski = Set{WeightLatticeElem}()

  # start recursion over highest_weight
  monomials = compute_monomials(
    V,
    birational_seq,
    ZZx,
    monomial_ordering,
    calc_highest_weight,
    no_minkowski,
  )
  # monomials = sort(collect(monomials); lt=((m1, m2) -> cmp(monomial_ordering, m1, m2) < 0))
  minkowski_gens = sort(
    collect(no_minkowski);
    by=(gen -> (sum(coefficients(gen)), reverse(Oscar._vec(coefficients(gen))))),
  )
  # output
  mb = MonomialBasis(V, birational_seq, monomial_ordering, monomials)
  set_attribute!(
    mb, :algorithm => basis_lie_highest_weight_compute, :minkowski_gens => minkowski_gens
  )
  return mb
end

function basis_coordinate_ring_kodaira_compute(
  L::LieAlgebra,
  highest_weight::Vector{Int},
  degree::Int,
  operators::Vector{RootSpaceElem},     # monomial x_i is corresponds to f_operators[i]
  monomial_ordering_symb::Symbol,
)
  # Pseudocode:

  # basis_coordinate_ring_kodaira_compute(highest_weight, degree)

  # returns all multiples of the given highest_weight up to degree 
  # such that for this ordering the monomial basis is not a Minkowski sum of bases of smaller multiples.
  #     return monomial bases for highest_weight and for each multiple up to degree, that is not the Minkowski sum 
  #       of smaller multiples, the missing monomials

  @req degree > 0 "Degree must be positive"
  R = root_system(L)
  highest_weight = WeightLatticeElem(R, highest_weight)

  birational_seq = birational_sequence(operators)

  ZZx, _ = polynomial_ring(ZZ, length(operators)) # for our monomials
  monomial_ordering = get_monomial_ordering(monomial_ordering_symb, ZZx, operators)

  # save computations from recursions
  calc_highest_weight = Dict{WeightLatticeElem,Set{ZZMPolyRingElem}}(
    zero(weight_lattice(R)) => Set([ZZx(1)])
  )

  # save all highest weights, for which the Minkowski-sum did not suffice to gain all monomials
  no_minkowski = Set{WeightLatticeElem}()
  monomials_k = Set{ZZMPolyRingElem}[]        # monomial basis of the module k*highest_weight
  monomials_new_k = Vector{ZZMPolyRingElem}[] # store the monomials that are not products of basis monomials of smaller degree
  sizehint!(monomials_k, degree)
  sizehint!(monomials_new_k, degree)
  monomial_basis_k = MonomialBasis[]

  # start recursion over degree
  for i in 1:degree
    monomials_minkowski_sum = Set{ZZMPolyRingElem}()
    dim_i = dim_of_simple_module(L, i * highest_weight)
    # iterate over all minkowski sums of previous steps
    for k in 1:div(i, 2)
      set_help = Set([p * q for p in monomials_k[i - k] for q in monomials_k[k]])
      union!(monomials_minkowski_sum, set_help)
      if length(monomials_minkowski_sum) == dim_i
        break
      end
    end
    if length(monomials_minkowski_sum) == dim_i
      @vprintln :BasisLieHighestWeight "for $(Int.(i * highest_weight)) everything is generated by smaller weights"
      monomials = monomials_minkowski_sum
      monomials_new = empty(monomials_minkowski_sum)
    else
      @vprintln :BasisLieHighestWeight "for $(Int.(i * highest_weight)) we have $(length(monomials_minkowski_sum)) and need $(dim_i) monomials"
      monomials = compute_monomials(
        L,
        birational_seq,
        ZZx,
        i * highest_weight,
        monomial_ordering,
        calc_highest_weight,
        no_minkowski,
      )
      monomials_new = setdiff(monomials, monomials_minkowski_sum)
      @vprintln :BasisLieHighestWeight "for $(Int.(i * highest_weight)) we added $(length(monomials_new)) monomials "

      # monomials = sort(collect(monomials); lt=((m1, m2) -> cmp(monomial_ordering, m1, m2) < 0))
      minkowski_gens = sort(
        collect(no_minkowski);
        by=(gen -> (sum(coefficients(gen)), reverse(Oscar._vec(coefficients(gen))))),
      )
    end

    mb = MonomialBasis(
      L, i * highest_weight, birational_seq, monomial_ordering, monomials
    )
    set_attribute!(mb, :algorithm => basis_coordinate_ring_kodaira_compute)
    monomials_new_sorted = sort(
      collect(monomials_new); lt=((m1, m2) -> cmp(monomial_ordering, m1, m2) < 0)
    )
    if isempty(monomials_new)
      set_attribute!(
        mb,
        :minkowski_gens => [k * highest_weight for k in findall(!isempty, monomials_new_k)],
        :new_monomials => nothing,
      )
    else
      set_attribute!(
        mb, :minkowski_gens => minkowski_gens, :new_monomials => monomials_new_sorted
      )
    end
    push!(monomials_k, monomials)
    push!(monomials_new_k, monomials_new_sorted)
    push!(monomial_basis_k, mb)
  end

  return collect(zip(monomial_basis_k, monomials_new_k))
end

function compute_monomials(
  V::ModuleData,
  birational_seq::BirationalSequence,
  ZZx::ZZMPolyRing,
  monomial_ordering::MonomialOrdering,
  calc_highest_weight::Dict{WeightLatticeElem,Set{ZZMPolyRingElem}},
  no_minkowski::Set{WeightLatticeElem},
)
  # This function calculates the monomial basis M_{highest_weight} recursively. The recursion saves all computed 
  # results in calc_highest_weight and we first check, if we already encountered this highest weight in a prior step. 
  # If this is not the case, we need to perform computations. The recursion works by using the Minkowski-sum. 
  # If M_{highest_weight} is the desired set of monomials (identified by the exponents as lattice points), it is known 
  # that for lambda_1 + lambda_2 = highest_weight we have M_{lambda_1} + M_{lambda_2} subseteq M_{highest_weight}. 
  # The complexity grows exponentially in the size of highest_weight. Therefore, it is very helpful to obtain a part of
  # M_{highest_weight} by going through all partitions of highest_weight and using the Minkowski-property. The base 
  # cases of the recursion are the fundamental weights highest_weight = [0, ..., 1, ..., 0]. In this case, or if the 
  # Minkowski-property did not find enough monomials, we need to perform the computations "by hand".

  # simple cases
  # we already computed the highest_weight result in a prior recursion step
  if haskey(calc_highest_weight, highest_weight(V))
    return calc_highest_weight[highest_weight(V)]
  elseif is_zero(highest_weight(V)) # we mathematically know the solution
    return Set(ZZx(1))
  end
  # calculation required
  # dim is number of monomials that we need to find, i.e. |M_{highest_weight}|.
  # if highest_weight is not a fundamental weight, partition into smaller summands is possible. This is the base case of
  # the recursion.
  if is_zero(highest_weight(V)) || is_fundamental_weight(highest_weight(V))
    push!(no_minkowski, highest_weight(V))
    monomials = add_by_hand(
      V, birational_seq, ZZx, monomial_ordering, Set{ZZMPolyRingElem}()
    )
    push!(calc_highest_weight, highest_weight(V) => monomials)
    return monomials
  else
    # use Minkowski-Sum for recursion
    monomials = Set{ZZMPolyRingElem}()
    sub_weights = sub_weights_proper(highest_weight(V))
    sort!(sub_weights; by=x -> sum(coefficients(x) .^ 2))
    # go through all partitions lambda_1 + lambda_2 = highest_weight until we have enough monomials or used all partitions
    for (ind_lambda_1, lambda_1) in enumerate(sub_weights)
      length(monomials) >= dim(V) && break

      lambda_2 = highest_weight(V) - lambda_1
      ind_lambda_2 = findfirst(==(lambda_2), sub_weights)::Int

      ind_lambda_1 > ind_lambda_2 && continue

      if isa(V, SimpleModuleData)
        M_lambda_1 = SimpleModuleData(base_lie_algebra(V), lambda_1)
        M_lambda_2 = SimpleModuleData(base_lie_algebra(V), lambda_2)
      elseif isa(V, DemazureModuleData)
        M_lambda_1 = DemazureModuleData(base_lie_algebra(V), lambda_1, weyl_group_elem(V))
        M_lambda_2 = DemazureModuleData(base_lie_algebra(V), lambda_2, weyl_group_elem(V))
      else
        error("unreachable")
      end

      mon_lambda_1 = compute_monomials(
        M_lambda_1,
        birational_seq,
        ZZx,
        monomial_ordering,
        calc_highest_weight,
        no_minkowski,
      )
      mon_lambda_2 = compute_monomials(
        M_lambda_2,
        birational_seq,
        ZZx,
        monomial_ordering,
        calc_highest_weight,
        no_minkowski,
      )
      # Minkowski-sum: M_{lambda_1} + M_{lambda_2} \subseteq M_{highest_weight}, if monomials get identified with 
      # points in ZZ^n
      union!(monomials, (p * q for p in mon_lambda_1 for q in mon_lambda_2))
    end
    # check if we found enough monomials

    if length(monomials) < dim(V)
      push!(no_minkowski, highest_weight)
      monomials = add_by_hand(
        V, birational_seq, ZZx, monomial_ordering, monomials
      )
    end

    push!(calc_highest_weight, highest_weight(V) => monomials)
    return monomials
  end
  
end

function add_new_monomials!(
  V::ModuleData,
  birational_seq::BirationalSequence,
  ZZx::ZZMPolyRing,
  matrices_of_operators::Vector{<:SMat{ZZRingElem}},
  monomial_ordering::MonomialOrdering,
  weightspaces::Dict{WeightLatticeElem,ZZRingElem},
  dim_weightspace::ZZRingElem,
  weight_w::WeightLatticeElem,
  monomials_in_weightspace::Dict{WeightLatticeElem,Set{ZZMPolyRingElem}},
  space::Dict{WeightLatticeElem,<:SMat{QQFieldElem}},
  v0::SRow{ZZRingElem},
  basis::Set{ZZMPolyRingElem},
  zero_coordinates::Vector{Int},
)
  # If a weightspace is missing monomials, we need to calculate them by trial and error. We would like to go through all
  # monomials in the order monomial_ordering and calculate the corresponding vector. If it extends the basis, we add it 
  # to the result and else we try the next one. We know, that all monomials that work lay in the weyl-polytope. 
  # Therefore, we only inspect the monomials that lie both in the weyl-polytope and the weightspace. Since the weyl-
  # polytope is bounded these are finitely many and we can sort them and then go through them, until we found enough.

  # get monomials that are in the weightspace, sorted by monomial_ordering
  poss_mon_in_weightspace = convert_lattice_points_to_monomials(
    ZZx,
    get_lattice_points_of_weightspace(
      operators_as_roots(birational_seq), RootSpaceElem(highest_weight(V) - weight_w),
      zero_coordinates,
    ),
  )
  isempty(poss_mon_in_weightspace) && error("The input seems to be invalid.")
  poss_mon_in_weightspace = sort(
    poss_mon_in_weightspace; lt=((m1, m2) -> cmp(monomial_ordering, m1, m2) < 0)
  )

  # check which monomials should get added to the basis
  i = 0
  if highest_weight(V) == weight_w # check if [0 0 ... 0] already in basis
    i += 1
  end
  number_mon_in_weightspace = length(monomials_in_weightspace[weight_w])
  # go through possible monomials one by one and check if it extends the basis
  while number_mon_in_weightspace < dim_weightspace
    i += 1
    mon = poss_mon_in_weightspace[i]
    if mon in basis
      continue
    end

    # check if the weight of each suffix is a weight of the module
    cancel = false
    for i in 1:(nvars(ZZx) - 1)
      if !haskey(
        weightspaces,
        highest_weight(V) - sum(
          exp * weight for (exp, weight) in
          Iterators.drop(zip(degrees(mon), operators_as_weights(birational_seq)), i)
        ),
      )
        cancel = true
        break
      end
    end
    if cancel
      continue
    end

    # calculate the vector vec associated with mon
    vec = calc_vec(v0, mon, matrices_of_operators)

    # check if vec extends the basis
    if !haskey(space, weight_w)
      space[weight_w] = sparse_matrix(QQ)
    end
    fl = Hecke._add_row_to_rref!(space[weight_w], change_base_ring(QQ, vec))
    if !fl
      continue
    end

    # save monom
    number_mon_in_weightspace += 1
    push!(basis, mon)
  end
end

function add_by_hand(
  V::ModuleData,
  birational_seq::BirationalSequence,
  ZZx::ZZMPolyRing,
  monomial_ordering::MonomialOrdering,
  basis::Set{ZZMPolyRingElem},
)
  # This function calculates the missing monomials by going through each non full weightspace and adding possible 
  # monomials manually by computing their corresponding vectors and checking if they enlargen the basis.

  # initialization
  # matrices g_i for (g_1^a_1 * ... * g_k^a_k)*v
  R = root_system(base_lie_algebra(V))
  matrices_of_operators = tensor_matrices_of_operators(
    base_lie_algebra(V), highest_weight(V), operators_as_roots(birational_seq)
  )
  space = Dict(zero(weight_lattice(R)) => sparse_matrix(QQ)) # span of basis vectors to keep track of the basis
  v0 = sparse_row(ZZ, [(1, 1)])  # starting vector v

  push!(basis, ZZx(1))
  # required monomials of each weightspace
  weightspaces = character(V)
  # sort the monomials from the minkowski-sum by their weightspaces
  monomials_in_weightspace = Dict{WeightLatticeElem,Set{ZZMPolyRingElem}}()
  for (weight_w, _) in weightspaces
    monomials_in_weightspace[weight_w] = Set{ZZMPolyRingElem}()
  end
  for mon in basis
    push!(monomials_in_weightspace[highest_weight(V) - weight(mon, birational_seq)], mon)
  end

  # only inspect weightspaces with missing monomials
  weights_with_non_full_weightspace = Set{WeightLatticeElem}()
  for (weight_w, dim_weightspace) in weightspaces
    if length(monomials_in_weightspace[weight_w]) != dim_weightspace
      push!(weights_with_non_full_weightspace, weight_w)
    end
  end

  # add all images from `monomials_in_weightspace` on `v0` to `space`
  for weight_w in weights_with_non_full_weightspace
    for mon in monomials_in_weightspace[weight_w]
      # calculate the vector vec associated with mon
      vec = calc_vec(v0, mon, matrices_of_operators)

      # check if vec extends the basis
      s = get!(space, weight_w) do
        sparse_matrix(QQ)
      end
      Hecke._add_row_to_rref!(s, change_base_ring(QQ, vec))
    end
  end

  # identify coordinates that are trivially zero because of the action on the generator
  zero_coordinates = compute_zero_coordinates(birational_seq, highest_weight(V))

  # calculate new monomials
  for weight_w in weights_with_non_full_weightspace
    dim_weightspace = weightspaces[weight_w]
    add_new_monomials!(
      V,
      birational_seq,
      ZZx,
      matrices_of_operators,
      monomial_ordering,
      weightspaces,
      dim_weightspace,
      weight_w,
      monomials_in_weightspace,
      space,
      v0,
      basis,
      zero_coordinates,
    )
  end
  return basis
end

function operators_asc_height(L::LieAlgebra)
  return positive_roots(root_system(L))
end

function operators_by_index(
  L::LieAlgebra,
  birational_seq::Vector{Int},
)
  return operators_asc_height(L)[birational_seq]
end

function operators_by_simple_roots(
  L::LieAlgebra,
  birational_seq::Vector{Vector{Int}},
)
  R = root_system(L)
  operators = map(birational_seq) do whgt_alpha
    root = RootSpaceElem(R, whgt_alpha)
    fl = is_positive_root(root)
    @req fl "Only positive roots are allowed as input"
    root
  end

  return operators
end

function operators_lusztig(L::LieAlgebra, reduced_expression::Vector{Int})
  # Computes the operators for the lusztig polytopes for a longest weyl-word 
  # reduced_expression.

  # \beta_k := (\alpha_{i_k}) s_{i_{k-1}} … s_{i_1}

  # F.e. for A, 2, [1, 2, 1], we get
  # \beta_1 = \alpha_1
  # \beta_2 = \alpha_1 + \alpha_2
  # \beta_3 = \alpha_2

  R = root_system(L)
  W = weyl_group(R)
  operators = map(1:length(reduced_expression)) do k
    root = simple_root(R, reduced_expression[k]) * W(reduced_expression[(k - 1):-1:1])
    fl = is_positive_root(root)
    @req fl "Only positive roots may occur here"
    root
  end
  return operators
end

function sub_weights(w::WeightLatticeElem)
  # returns list of weights v != 0, highest_weight with 0 <= v <= w elementwise
  @req is_dominant(w) "The input must be a dominant weight"
  R = root_system(w)
  map(AbstractAlgebra.ProductIterator([0:w[i] for i in 1:rank(R)])) do coeffs
    WeightLatticeElem(R, coeffs)
  end
end

function sub_weights_proper(w::WeightLatticeElem)
  # returns list of weights v != 0, highest_weight with 0 <= v <= w elementwise, but neither 0 nor w
  return filter(x -> !iszero(x) && x != w, sub_weights(w))
end
