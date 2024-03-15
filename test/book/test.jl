const excluded = [
                  # Excluded due to performance issues
                  "markwig-ristau-schleis-faithful-tropicalization/eliminate_xz",
                  "markwig-ristau-schleis-faithful-tropicalization/eliminate_yz",
                  "number-theory/cohenlenstra.jlcon",
                  "bies-turner-string-theory-applications/SU5.jlcon",
                  "brandhorst-zach-fibration-hopping/vinberg_2.jlcon",
                  "brandhorst-zach-fibration-hopping/vinberg_3.jlcon",
                  "cornerstones/polyhedral-geometry/ch-benchmark.jlcon",
                  "number-theory/unit_plot.jlcon",                                            
                  "number-theory/intro_plot_lattice.jlcon",                                   
                  "number-theory/intro5_0.jlcon",                                             
                  # Excluded for easier testing
                  # "number-theory",
                  "groups",
                  "algebraic-geometry",
                  "introduction",
                  "specialized/boehm-breuer-git-fans",
                  "specialized/markwig-ristau-schleis-faithful-tropicalization",
                  "specialized/holt-ren-tropical-geometry",
                  # "specialized/bies-turner-string-theory-applications",
                  "specialized/aga-boehm-hoffmann-markwig-traore",
                  "specialized/joswig-kastner-lorenz-confirmable-workflows",
                  # "cornerstones/number-theory",
                  "cornerstones/groups",
                  "introduction/introduction",
                  "specialized/eder-mohr-ideal-theoretic",
                  # "specialized/kuehne-schroeter-matroids",
                  "specialized/rose-sturmfels-telen-tropical-implicitization",
                  # "specialized/fang-fourier-monomial-bases",
                  "specialized/brandhorst-zach-fibration-hopping",
                  # "specialized/breuer-nebe-parker-orthogonal-discriminants",
                  "cornerstones/algebraic-geometry",
                  "specialized/decker-schmitt-invariant-theory",
                  # "specialized/bies-kastner-toric-geometry",
                  # Excluded for Plots.jl
                  "g-vectors.jl",
                  "g-vectors-upper-bound.jl",
                 ]  

const broken = [
                  # Something broken in Oscar
                  "specialized/breuer-nebe-parker-orthogonal-discriminants/expl_syl.jlcon",

                  # weird errors with last line that has no output:
                  "specialized/bies-turner-string-theory-applications/SU5.jlcon",
                  "specialized/boehm-breuer-git-fans/explG25_1.jlcon",
                  "specialized/boehm-breuer-git-fans/explG25_8.jlcon",
                  "specialized/aga-boehm-hoffmann-markwig-traore/graphname.jlcon",
                  "specialized/rose-sturmfels-telen-tropical-implicitization/gen_impl.jlcon",
                  "specialized/rose-sturmfels-telen-tropical-implicitization/hyperdet.jlcon",
                  "specialized/rose-sturmfels-telen-tropical-implicitization/pol_from_surface.jlcon",
                  "specialized/rose-sturmfels-telen-tropical-implicitization/chow_fan.jlcon",
                  "specialized/rose-sturmfels-telen-tropical-implicitization/chow_transl.jlcon",

                  # TODO: need to fix column width for output?
                  "specialized/markwig-ristau-schleis-faithful-tropicalization/eliminate_xz.jlcon",

                  # non-stable:
                  "specialized/joswig-kastner-lorenz-confirmable-workflows/versioninfo.jlcon",

                  # output changed in oscar master? TODO check + adapt
                  "specialized/decker-schmitt-invariant-theory/gleason.jlcon",

                  # FIXME: MethodError: no method matching (::Oscar.MPolyAnyMap{…})(::Oscar.MPolyAnyMap{…}, ::Vector{…}) 
                  # function missing on master?
                  "specialized/decker-schmitt-invariant-theory/cox_ring.jlcon",
               ]
const skipped = [
                  # sometimes very slow: 4000-30000s
                  "specialized/brandhorst-zach-fibration-hopping/vinberg_2.jlcon",
                  # very slow: 24000s
                  "cornerstones/number-theory/cohenlenstra.jlcon",
                  # ultra slow: time unknown
                  "specialized/markwig-ristau-schleis-faithful-tropicalization/eliminate_yz.jlcon",

                  # somewhat slow (~300s)
                  "cornerstones/polyhedral-geometry/ch-benchmark.jlcon",
                  "specialized/brandhorst-zach-fibration-hopping/vinberg_3.jlcon",

                  # needs Mockdule:
                  #   defines `l(a,b)`:
                  "cornerstones/number-theory/unit_log_plot.jl",
                  #   printout changes on subsequent runs due to other variables
                  "cornerstones/groups/cohomology.jlcon",
                  #   defines vars that affect other tests... (eder-mohr...)
                  "cornerstones/groups/genchar.jlcon",
                ]

dispsize = (40, 130)

using REPL
using Random
using Pkg
import Random.Xoshiro
using Test
include(joinpath(pkgdir(REPL),"test","FakeTerminals.jl"))


function normalize_repl_output(s::AbstractString)
  result = string(s)
  lafter = length(result)
  lbefore = lafter+1
  while lafter < lbefore
    lbefore = lafter
    result = replace(result, r"^       "m => "")
    result = strip(result)
    result = replace(result, r"julia>$"s => "")
    result = replace(result, r"^\s*(?:#\d+)?(.* \(generic function with ).*\n"m => s"\1\n")
    result = replace(result, r"^\s*[0-9\.]+ seconds \(.* allocations: .*\)$"m => "<timing>\n")
    # this removes the package version slug, filename and linenumber
    result = replace(result, r" @ \w* ?~/\.julia/packages/(?:Nemo|Hecke|AbstractAlgebra|Polymake)/\K[\w\d]+/.*\.jl:\d+"m => "")
    lafter = length(result)
  end
  return strip(result)
end


function sanitize_input(s::AbstractString)
  result = s
  result = normalize_repl_output(result)
  return result
end

function sanitize_output(s::AbstractString)
  result = s
  # println("length before: ", length(result))
  lafter = length(result)
  lbefore = lafter+1
  while lafter < lbefore
    lbefore = lafter
    result = replace(result, r"\r\e\[\d+[A-Z]"=>"")
    result = replace(result, r"\e\[\?\d+[a-z]"=>"")
    result = replace(result, r"\r\r\n"=>"")
    result = replace(result, r"julia> julia> julia>" => "julia>")
    lafter = length(result)
  end
  result = replace(result, r"julia> visualize\(PC\)julia> visualize\(PC\)" => "julia> visualize(PC)")
  result = normalize_repl_output(result)
  # println("length after: ", length(result))
  return result
end

function set_task_rngstate!(state::Xoshiro)
  Random.setstate!(Random.default_rng(), state.s0, state.s1, state.s2, state.s3, state.s4)
end
function get_task_rngstate!(state::Xoshiro)
  t = current_task()
  Random.setstate!(state, t.rngState0, t.rngState1, t.rngState2, t.rngState3, t.rngState4)
end

function run_repl_string(s::AbstractString, rng::Random.Xoshiro; jlcon_mode=true)
  input_string = s
  if jlcon_mode
    input_string = "\e[200~$s\e[201~\n"
  end
  input = Pipe()
  output = Pipe()
  err = Pipe()
  Base.link_pipe!(input, reader_supports_async=true, writer_supports_async=true)
  #outputbuf = IOBuffer()
  Base.link_pipe!(output, reader_supports_async=true, writer_supports_async=true)
  Base.link_pipe!(err, reader_supports_async=true, writer_supports_async=true)
  stdin_write = input.in
  out_stream = IOContext(output.in, :displaysize=>dispsize)
  options = REPL.Options(confirm_exit=false, hascolor=false)
  # options.extra_keymap = REPL.LineEdit.escape_defaults
  repl = REPL.LineEditREPL(FakeTerminals.FakeTerminal(input.out, out_stream, err.in, options.hascolor), options.hascolor, false)
  repl.options = options
  # repl.specialdisplay = REPL.REPLDisplay(repl)
  repltask = @async begin
    redirect_stdout(out_stream) do
      set_task_rngstate!(rng)
      REPL.run_repl(repl)
      get_task_rngstate!(rng)
    end
  end
  input_task = @async write(stdin_write, input_string)
  output_task = @async read(output.out, String)
  wait(input_task)
  input_task = @async write(stdin_write, "\x04")
  wait(input_task)
  wait(repltask)
  close(output)
  result = fetch(output_task)
  return sanitize_output(result)
end

# add overlay project for plots
custom_load_path = []
copy!(custom_load_path, Base.DEFAULT_LOAD_PATH)
curdir = pwd()
act_proj = dirname(Base.active_project())
try
plots = mktempdir()
Pkg.activate(plots; io=devnull)
Pkg.add("Plots"; io=devnull)
Pkg.activate("$act_proj"; io=devnull)
pushfirst!(custom_load_path, plots)

oefile = joinpath(Oscar.oscardir, "test/book/ordered_examples.json")
ordered_examples = load(oefile)
if isdefined(Main, :run_only) && run_only !== nothing
  ordered_examples = Dict("$run_only" => ordered_examples[run_only])
end
withenv("LINES" => dispsize[1], "COLUMNS" => dispsize[2], "DISPLAY" => "") do
  for (chapter, example_list) in ordered_examples
    cd(curdir)
    @testset "$chapter" verbose=true begin
      println(chapter)
      copy!(LOAD_PATH, custom_load_path)
      auxmain = joinpath(Oscar.oscardir, "test/book", chapter, "auxiliary_code", "main.jl")
      if isfile(auxmain)
        # add overlay project for aux file
        # and run it from temp dir
        temp = mktempdir()
        Pkg.activate(temp; io=devnull)
        Pkg.develop(path=act_proj; io=devnull)
        pushfirst!(LOAD_PATH, "$act_proj")
        cp(auxmain,joinpath(temp, "main.jl"))
        cd(temp)
        include(joinpath(temp,"main.jl"))
        LOAD_PATH[1] = temp
        Pkg.activate("$act_proj"; io=devnull)
      end
      Oscar.set_seed!(42)
      Oscar.randseed!(42)
      rng = copy(Random.default_rng())
      for example in example_list
        full_file = joinpath(chapter, example)
        exclude = filter(s->occursin(s, full_file), excluded)
        if length(exclude) == 0
          println("   $example$(full_file in skipped ? ": skip" :
                                full_file in broken ? ": broken" : "")")
          filetype = endswith(example, "jlcon") ? :jlcon : 
                     endswith(example, "jl") ? :jl : :unknown
          content = read(joinpath(Oscar.oscardir, "test/book", full_file), String)
          if filetype == :jlcon && !occursin("julia> ", content)
            filetype = :jl
            @warn "possibly wrong file type: $full_file"
          end
          if full_file in skipped
            @test run_repl_string(content, rng) isa AbstractString skip=true
          elseif filetype == :jlcon
            content = sanitize_input(content)
            computed = run_repl_string(content, rng)
            @test normalize_repl_output(content) == computed broken=(full_file in broken)
          elseif filetype == :jl
            if occursin("# output\n", content)
              (code, res) = split(content, "# output\n"; limit=2)
              # TODO do we want to compare with `res` ?
              @test run_repl_string(code, rng; jlcon_mode=false) isa AbstractString broken=(full_file in broken)
            else
              @test run_repl_string(content, rng; jlcon_mode=false) isa AbstractString broken=(full_file in broken)
            end
          else
            @warn "unknown file type: $full_file"
          end
        # else
        #   println("   "*example*" excluded")
        end
      end
    end
  end
end
finally
  cd(curdir)
  copy!(LOAD_PATH, Base.DEFAULT_LOAD_PATH)
  Pkg.activate("$act_proj"; io=devnull)
end
nothing
