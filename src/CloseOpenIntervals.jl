module CloseOpenIntervals

using Static: StaticInt, Zero, One
export CloseOpen, SafeCloseOpen

abstract type AbstractCloseOpen{L <: Integer, U <: Integer} <: AbstractUnitRange{Int} end
for T ∈ (:CloseOpen,:SafeCloseOpen)
  @eval begin
    struct $T{L <: Integer, U <: Integer} <: AbstractCloseOpen{L,U}
      start::L
      upper::U
      @inline $T{L,U}(l::L,u::U) where {L <: Integer, U <: Integer} = new{L,U}(l,u)
    end
    @inline $T(s::S, u::U) where {S,U} = $T{S,U}(s, u)
    @inline $T(len::T) where {T<:Integer} = $T{Zero,T}(Zero(), len)
  end
end

@inline Base.first(r::AbstractCloseOpen) = getfield(r,:start)
@inline Base.first(r::AbstractCloseOpen{StaticInt{F}}) where {F} = StaticInt{F}()
@inline Base.step(::AbstractCloseOpen) = One()
@inline Base.last(r::AbstractCloseOpen{<:Integer,I}) where {I} = getfield(r,:upper) - oneunit(I)
@inline Base.last(r::AbstractCloseOpen{<:Integer,StaticInt{L}}) where {L} = StaticInt{L}() - One()
@inline Base.length(r::AbstractCloseOpen) = getfield(r,:upper) - getfield(r,:start)
@inline Base.length(r::AbstractCloseOpen{Zero}) = getfield(r,:upper)

@inline Base.iterate(r::CloseOpen) = (i = Int(first(r)); (i, i))
@inline Base.iterate(r::SafeCloseOpen) = (i = Int(first(r)); i ≥ getfield(r, :upper) ? nothing : (i, i))
@inline Base.iterate(r::AbstractCloseOpen, i::Integer) = (i += one(i)) ≥ getfield(r, :upper) ? nothing : (i, i)

import ArrayInterface
ArrayInterface.known_first(::Type{<:AbstractCloseOpen{StaticInt{F}}}) where {F} = F
ArrayInterface.known_step(::Type{<:AbstractCloseOpen}) = 1
ArrayInterface.known_last(::Type{<:AbstractCloseOpen{<:Any,StaticInt{L}}}) where {L} = L - 1
ArrayInterface.known_length(::Type{<:AbstractCloseOpen{StaticInt{F},StaticInt{L}}}) where {F,L} = L - F

Base.IteratorSize(::Type{<:AbstractCloseOpen}) = Base.HasShape{1}()
Base.IteratorEltype(::Type{<:AbstractCloseOpen}) = Base.HasEltype()
@inline Base.size(r::AbstractCloseOpen) = (length(r),)
@inline Base.eltype(r::AbstractCloseOpen) = Int

@inline function Base.IteratorsMD.__inc(state::Tuple{Int,Int,Vararg{Int}}, indices::Tuple{AbstractCloseOpen,Vararg{Base.IteratorsMD.OrdinalRangeInt}})
  rng = indices[1]
  I1 = state[1] + step(rng)
  if Base.IteratorsMD.__is_valid_range(I1, rng) && state[1] != last(rng)
    return true, (I1, Base.tail(state)...)
  end
  valid, I = Base.IteratorsMD.__inc(Base.tail(state), Base.tail(indices))
  return valid, (convert(typeof(I1), first(rng)), I...)
end
end
