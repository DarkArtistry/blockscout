defmodule Explorer.Chain.Beacon.Slashing do
  @moduledoc """
  Models a slashing event in the beacon chain.
  """

  use Explorer.Schema

  alias Explorer.{Chain, PagingOptions, SortingHelper}

  @required_attrs ~w(slot epoch slashed_validator_index reason)a
  @optional_attrs ~w(slasher_validator_index details)a

  @reasons ~w(proposer_slashing attester_slashing)a

  @primary_key {:id, :id, autogenerate: true}
  typed_schema "beacon_slashings" do
    field(:slot, :integer, null: false)
    field(:epoch, :integer, null: false)
    field(:slashed_validator_index, :integer, null: false)
    field(:slasher_validator_index, :integer)
    field(:reason, :string, null: false)
    field(:details, :string)

    timestamps()
  end

  @doc """
  Validates that the `attrs` are valid.
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(slashing, attrs) do
    slashing
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_inclusion(:reason, @reasons)
  end

  @sorting [desc: :slot]

  @doc """
  Fetches all slashings with pagination.
  """
  @spec all([Chain.paging_options() | Chain.api?()]) :: [t()]
  def all(options \\ []) do
    slashing_list_query(:all, nil, options)
  end

  @doc """
  Fetches slashings by validator index (as slashed).
  """
  @spec by_slashed_validator(integer(), [Chain.paging_options() | Chain.api?()]) :: [t()]
  def by_slashed_validator(validator_index, options \\ []) do
    slashing_list_query(:slashed_validator_index, validator_index, options)
  end

  defp slashing_list_query(entity, value, options) do
    paging_options = Keyword.get(options, :paging_options, Chain.default_paging_options())

    __MODULE__
    |> then(fn q ->
      case entity do
        :slashed_validator_index -> where(q, [s], s.slashed_validator_index == ^value)
        :all -> q
      end
    end)
    |> SortingHelper.apply_sorting(@sorting, [])
    |> SortingHelper.page_with_sorting(paging_options, @sorting, [])
    |> Chain.select_repo(options).all()
  end
end
