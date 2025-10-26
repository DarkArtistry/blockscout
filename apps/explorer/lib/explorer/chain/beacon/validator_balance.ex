defmodule Explorer.Chain.Beacon.ValidatorBalance do
  @moduledoc """
  Models a validator balance history entry in the beacon chain.
  """

  use Explorer.Schema

  alias Explorer.Chain
  alias Explorer.Chain.Beacon.Validator

  @required_attrs ~w(validator_index epoch balance effective_balance)a

  @primary_key false
  typed_schema "beacon_validator_balances" do
    field(:validator_index, :integer, null: false)
    field(:epoch, :integer, null: false)
    field(:balance, :decimal, null: false)
    field(:effective_balance, :decimal, null: false)

    timestamps()
  end

  @doc """
  Validates that the `attrs` are valid.
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(balance, attrs) do
    balance
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint([:validator_index, :epoch])
  end

  @doc """
  Fetches balance history for a validator.
  """
  @spec by_validator_index(integer(), [Chain.paging_options() | Chain.api?()]) :: [t()]
  def by_validator_index(validator_index, options \\ []) do
    paging_options = Keyword.get(options, :paging_options, Chain.default_paging_options())

    query =
      from(vb in __MODULE__,
        where: vb.validator_index == ^validator_index,
        order_by: [desc: vb.epoch],
        limit: ^paging_options.page_size
      )

    Chain.select_repo(options).all(query)
  end

  @doc """
  Fetches the latest balance for a validator.
  """
  @spec latest_by_validator_index(integer(), [Chain.api?()]) :: t() | nil
  def latest_by_validator_index(validator_index, options \\ []) do
    query =
      from(vb in __MODULE__,
        where: vb.validator_index == ^validator_index,
        order_by: [desc: vb.epoch],
        limit: 1
      )

    Chain.select_repo(options).one(query)
  end
end
