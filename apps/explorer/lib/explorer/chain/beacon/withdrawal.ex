defmodule Explorer.Chain.Beacon.Withdrawal do
  @moduledoc """
  Models a withdrawal in the beacon chain.
  """

  use Explorer.Schema

  alias Explorer.{Chain, PagingOptions, SortingHelper}
  alias Explorer.Chain.{Address, Hash}

  @required_attrs ~w(index validator_index address amount)a
  @optional_attrs ~w(slot epoch)a

  @primary_key {:id, :id, autogenerate: true}
  typed_schema "beacon_withdrawals" do
    field(:index, :integer, null: false)
    field(:validator_index, :integer, null: false)
    field(:address, Hash.Address, null: false)
    field(:amount, :decimal, null: false)
    field(:slot, :integer)
    field(:epoch, :integer)

    timestamps()
  end

  @doc """
  Validates that the `attrs` are valid.
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(withdrawal, attrs) do
    withdrawal
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:index)
  end

  @sorting [desc: :index]

  @doc """
  Fetches all withdrawals with pagination.
  """
  @spec all([Chain.paging_options() | Chain.api?()]) :: [t()]
  def all(options \\ []) do
    withdrawal_list_query(:all, nil, options)
  end

  @doc """
  Fetches withdrawals by validator index.
  """
  @spec by_validator_index(integer(), [Chain.paging_options() | Chain.api?()]) :: [t()]
  def by_validator_index(validator_index, options \\ []) do
    withdrawal_list_query(:validator_index, validator_index, options)
  end

  @doc """
  Fetches withdrawals by address.
  """
  @spec by_address(Hash.Address.t(), [Chain.paging_options() | Chain.api?()]) :: [t()]
  def by_address(address, options \\ []) do
    withdrawal_list_query(:address, address, options)
  end

  defp withdrawal_list_query(entity, value, options) do
    paging_options = Keyword.get(options, :paging_options, Chain.default_paging_options())

    __MODULE__
    |> then(fn q ->
      case entity do
        :validator_index -> where(q, [w], w.validator_index == ^value)
        :address -> where(q, [w], w.address == ^value)
        :all -> q
      end
    end)
    |> SortingHelper.apply_sorting(@sorting, [])
    |> SortingHelper.page_with_sorting(paging_options, @sorting, [])
    |> Chain.select_repo(options).all()
  end

  @doc """
  Returns total withdrawn amount for a validator.
  """
  @spec total_withdrawn_by_validator(integer(), [Chain.api?()]) :: Decimal.t()
  def total_withdrawn_by_validator(validator_index, options \\ []) do
    query =
      from(w in __MODULE__,
        where: w.validator_index == ^validator_index,
        select: sum(w.amount)
      )

    Chain.select_repo(options).one(query) || Decimal.new(0)
  end
end
