defmodule Explorer.Chain.Beacon.Validator do
  @moduledoc """
  Models a validator in the beacon chain.
  """

  use Explorer.Schema

  alias Explorer.{Chain, PagingOptions, Repo, SortingHelper}

  @required_attrs ~w(index pubkey status)a
  @optional_attrs ~w(withdrawal_credentials effective_balance slashed activation_eligibility_epoch activation_epoch exit_epoch withdrawable_epoch last_attestation_slot)a

  @statuses ~w(pending_initialized pending_queued active_ongoing active_exiting active_slashed exited_unslashed exited_slashed withdrawal_possible withdrawal_done)

  @primary_key false
  typed_schema "beacon_validators" do
    field(:index, :integer, primary_key: true, null: false)
    field(:pubkey, :string, null: false)
    field(:withdrawal_credentials, :string)
    field(:effective_balance, :decimal)
    field(:slashed, :boolean, default: false)
    field(:activation_eligibility_epoch, :integer)
    field(:activation_epoch, :integer)
    field(:exit_epoch, :integer)
    field(:withdrawable_epoch, :integer)
    field(:status, :string, null: false)
    field(:last_attestation_slot, :integer)

    timestamps()
  end

  @doc """
  Validates that the `attrs` are valid.
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(validator, attrs) do
    validator
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:index, name: :beacon_validators_pkey)
    |> unique_constraint(:pubkey)
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Returns all validator statuses.
  """
  def statuses, do: @statuses

  @sorting [desc: :index]

  @doc """
  Fetches all validators with pagination.

  ## Parameters
  - `options`: A keyword list of options:
    - `:paging_options` - Pagination configuration
    - `:filter` - Filter by status
    - `:necessity_by_association` - Associations to preload
    - `:api?` - Boolean flag for API context

  ## Returns
  - A list of validators with requested associations preloaded
  """
  @spec all([Chain.paging_options() | Chain.necessity_by_association() | Chain.api?() | {:filter, map()}]) :: [t()]
  def all(options \\ []) do
    validator_list_query(:all, nil, options)
  end

  @doc """
  Fetches a validator by index.
  """
  @spec by_index(integer(), [Chain.necessity_by_association() | Chain.api?()]) :: t() | nil
  def by_index(index, options \\ []) do
    validator_list_query(:index, index, options)
    |> Chain.select_repo(options).one()
  end

  @doc """
  Fetches a validator by pubkey.
  """
  @spec by_pubkey(String.t(), [Chain.necessity_by_association() | Chain.api?()]) :: t() | nil
  def by_pubkey(pubkey, options \\ []) do
    validator_list_query(:pubkey, pubkey, options)
    |> Chain.select_repo(options).one()
  end

  @doc """
  Fetches slashed validators.
  """
  @spec slashed([Chain.paging_options() | Chain.necessity_by_association() | Chain.api?()]) :: [t()]
  def slashed(options \\ []) do
    validator_list_query(:slashed, true, options)
  end

  @doc """
  Returns the count of validators by status.
  """
  @spec count_by_status([Chain.api?()]) :: %{String.t() => integer()}
  def count_by_status(options \\ []) do
    query =
      from(v in __MODULE__,
        group_by: v.status,
        select: {v.status, count(v.index)}
      )

    Chain.select_repo(options).all(query)
    |> Map.new()
  end

  @doc """
  Returns the total count of validators.
  """
  @spec total_count([Chain.api?()]) :: integer()
  def total_count(options \\ []) do
    Chain.select_repo(options).aggregate(__MODULE__, :count, :index)
  end

  defp validator_list_query(entity, value, options) do
    paging_options = Keyword.get(options, :paging_options, Chain.default_paging_options())
    filter = Keyword.get(options, :filter, %{})

    {required_necessity_by_association, optional_necessity_by_association} =
      options |> Keyword.get(:necessity_by_association, %{}) |> Enum.split_with(fn {_, v} -> v == :required end)

    __MODULE__
    |> then(fn q ->
      case entity do
        :index -> where(q, [validator], validator.index == ^value)
        :pubkey -> where(q, [validator], validator.pubkey == ^value)
        :slashed -> where(q, [validator], validator.slashed == ^value)
        :all -> q
      end
    end)
    |> apply_filter(filter)
    |> SortingHelper.apply_sorting(@sorting, [])
    |> SortingHelper.page_with_sorting(paging_options, @sorting, [])
    |> Chain.join_associations(Map.new(required_necessity_by_association))
    |> then(fn q ->
      if entity in [:index, :pubkey] do
        q
      else
        Chain.select_repo(options).all(q)
      end
    end)
  end

  defp apply_filter(query, filter) when map_size(filter) == 0, do: query

  defp apply_filter(query, %{status: status}) when is_binary(status) do
    where(query, [v], v.status == ^status)
  end

  defp apply_filter(query, %{status: statuses}) when is_list(statuses) do
    where(query, [v], v.status in ^statuses)
  end

  defp apply_filter(query, _), do: query
end
