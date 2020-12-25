defmodule Deftype.Attr do
  @moduledoc """
  Utility functions for accessing attrs.
  """

  @type key :: atom()
  @type type :: any()
  @type meta :: Keyword.t()

  @type t :: {key(), type(), meta()}

  @doc """
  The key of an attr.
  """
  @spec key(t) :: key
  def key({k, _, _}), do: k

  @doc """
  The type of an attr.
  """
  @spec type(t) :: type
  def type({_, t, _}), do: t

  @doc """
  The meta of an attr.
  """
  @spec meta(t) :: meta
  def meta({_, _, m}), do: m
end
