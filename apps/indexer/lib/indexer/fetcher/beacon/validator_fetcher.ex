defmodule Indexer.Fetcher.Beacon.ValidatorFetcher do
  @moduledoc """
  Fetches validator data from Beacon Chain API and stores in database.
  """

  use GenServer

  require Logger

  alias Explorer.{Chain, Repo}
  alias Explorer.Chain.Beacon.{Validator, ValidatorBalance}
  alias Indexer.Fetcher.Beacon.Client

  @fetch_interval :timer.minutes(5)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    send(self(), :fetch)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:fetch, state) do
    fetch_and_store_validators()
    schedule_next_fetch()
    {:noreply, state}
  end

  defp fetch_and_store_validators do
    Logger.info("Fetching validators from beacon chain...")

    with {:ok, %{"data" => validators}} <- Client.get_validators(),
         {:ok, %{"data" => balances}} <- Client.get_validator_balances() do
      Logger.info("Received #{length(validators)} validators")

      # Create a map of balances for quick lookup
      balance_map =
        balances
        |> Enum.map(fn balance ->
          {String.to_integer(balance["index"]), balance["balance"]}
        end)
        |> Map.new()

      # Process validators
      validators
      |> Enum.each(fn validator_data ->
        process_validator(validator_data, balance_map)
      end)

      Logger.info("Successfully processed validators")
    else
      {:error, reason} ->
        Logger.error("Failed to fetch validators: #{inspect(reason)}")
    end
  end

  defp process_validator(validator_data, balance_map) do
    index = String.to_integer(validator_data["index"])
    validator_info = validator_data["validator"]
    status = validator_data["status"]

    attrs = %{
      index: index,
      pubkey: validator_info["pubkey"],
      withdrawal_credentials: validator_info["withdrawal_credentials"],
      effective_balance: parse_balance(validator_info["effective_balance"]),
      slashed: validator_info["slashed"],
      activation_eligibility_epoch: parse_epoch(validator_info["activation_eligibility_epoch"]),
      activation_epoch: parse_epoch(validator_info["activation_epoch"]),
      exit_epoch: parse_epoch(validator_info["exit_epoch"]),
      withdrawable_epoch: parse_epoch(validator_info["withdrawable_epoch"]),
      status: status
    }

    case Repo.insert(
           Validator.changeset(%Validator{}, attrs),
           on_conflict: {:replace_all_except, [:inserted_at]},
           conflict_target: :index
         ) do
      {:ok, _validator} ->
        # Store balance if available
        if balance = balance_map[index] do
          store_validator_balance(index, balance)
        end

      {:error, changeset} ->
        Logger.error("Failed to insert validator #{index}: #{inspect(changeset.errors)}")
    end
  end

  defp store_validator_balance(validator_index, balance) do
    # Get current epoch (simplified - in production you'd fetch this from beacon chain)
    # For now, we'll use a timestamp-based calculation
    genesis_time = 1_749_014_203
    seconds_per_slot = 12
    slots_per_epoch = 32

    current_time = DateTime.utc_now() |> DateTime.to_unix()
    current_epoch = div(current_time - genesis_time, seconds_per_slot * slots_per_epoch)

    attrs = %{
      validator_index: validator_index,
      epoch: current_epoch,
      balance: parse_balance(balance),
      effective_balance: parse_balance(balance)
    }

    Repo.insert(
      ValidatorBalance.changeset(%ValidatorBalance{}, attrs),
      on_conflict: :nothing,
      conflict_target: [:validator_index, :epoch]
    )
  end

  defp parse_balance(balance) when is_binary(balance) do
    case Integer.parse(balance) do
      {value, _} -> Decimal.new(value)
      :error -> Decimal.new(0)
    end
  end

  defp parse_balance(balance) when is_integer(balance), do: Decimal.new(balance)
  defp parse_balance(_), do: Decimal.new(0)

  defp parse_epoch(epoch) when is_binary(epoch) do
    case Integer.parse(epoch) do
      {value, _} ->
        # Ethereum uses max uint64 for FAR_FUTURE_EPOCH
        if value >= 18_446_744_073_709_551_615, do: nil, else: value

      :error ->
        nil
    end
  end

  defp parse_epoch(epoch) when is_integer(epoch) do
    if epoch >= 18_446_744_073_709_551_615, do: nil, else: epoch
  end

  defp parse_epoch(_), do: nil

  defp schedule_next_fetch do
    Process.send_after(self(), :fetch, @fetch_interval)
  end
end
