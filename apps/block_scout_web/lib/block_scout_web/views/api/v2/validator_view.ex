defmodule BlockScoutWeb.API.V2.ValidatorView do
  use BlockScoutWeb, :view

  alias BlockScoutWeb.API.V2.Helper

  def render("stability_validators.json", %{validators: validators, next_page_params: next_page_params}) do
    %{"items" => Enum.map(validators, &prepare_stability_validator(&1)), "next_page_params" => next_page_params}
  end

  def render("blackfort_validators.json", %{validators: validators, next_page_params: next_page_params}) do
    %{"items" => Enum.map(validators, &prepare_blackfort_validator(&1)), "next_page_params" => next_page_params}
  end

  def render("zilliqa_validators.json", %{validators: validators, next_page_params: next_page_params}) do
    %{"items" => Enum.map(validators, &prepare_zilliqa_validator(&1)), "next_page_params" => next_page_params}
  end

  def render("zilliqa_validator.json", %{validator: validator}) do
    validator
    |> prepare_zilliqa_validator()
    |> Map.merge(%{
      "peer_id" => validator.peer_id,
      "control_address" =>
        Helper.address_with_info(nil, validator.control_address, validator.control_address_hash, true),
      "reward_address" => Helper.address_with_info(nil, validator.reward_address, validator.reward_address_hash, true),
      "signing_address" =>
        Helper.address_with_info(nil, validator.signing_address, validator.signing_address_hash, true),
      "added_at_block_number" => validator.added_at_block_number,
      "stake_updated_at_block_number" => validator.stake_updated_at_block_number
    })
  end

  def render("beacon_validators.json", %{validators: validators, next_page_params: next_page_params}) do
    %{"items" => Enum.map(validators, &prepare_beacon_validator(&1)), "next_page_params" => next_page_params}
  end

  def render("beacon_validator.json", %{
        validator: validator,
        balances: balances,
        withdrawals: withdrawals,
        slashings: slashings
      }) do
    validator
    |> prepare_beacon_validator()
    |> Map.merge(%{
      "balance_history" => Enum.map(balances, &prepare_beacon_balance(&1)),
      "withdrawals" => Enum.map(withdrawals, &prepare_beacon_withdrawal(&1)),
      "slashings" => Enum.map(slashings, &prepare_beacon_slashing(&1))
    })
  end

  defp prepare_stability_validator(validator) do
    %{
      "address" => Helper.address_with_info(nil, validator.address, validator.address_hash, true),
      "state" => validator.state,
      "blocks_validated_count" => validator.blocks_validated
    }
  end

  defp prepare_blackfort_validator(validator) do
    %{
      "address" => Helper.address_with_info(nil, validator.address, validator.address_hash, true),
      "name" => validator.name,
      "commission" => validator.commission,
      "self_bonded_amount" => validator.self_bonded_amount,
      "delegated_amount" => validator.delegated_amount,
      "slashing_status" => %{
        "slashed" => validator.slashing_status_is_slashed,
        "block_number" => validator.slashing_status_by_block,
        "multiplier" => validator.slashing_status_multiplier
      }
    }
  end

  @spec prepare_zilliqa_validator(Explorer.Chain.Zilliqa.Staker.t()) :: map()
  defp prepare_zilliqa_validator(validator) do
    %{
      "bls_public_key" => validator.bls_public_key,
      "index" => validator.index,
      "balance" => to_string(validator.balance)
    }
  end

  defp prepare_beacon_validator(validator) do
    %{
      "index" => validator.index,
      "pubkey" => validator.pubkey,
      "withdrawal_credentials" => validator.withdrawal_credentials,
      "effective_balance" => to_string(validator.effective_balance || 0),
      "slashed" => validator.slashed,
      "activation_eligibility_epoch" => validator.activation_eligibility_epoch,
      "activation_epoch" => validator.activation_epoch,
      "exit_epoch" => validator.exit_epoch,
      "withdrawable_epoch" => validator.withdrawable_epoch,
      "status" => validator.status,
      "last_attestation_slot" => validator.last_attestation_slot
    }
  end

  defp prepare_beacon_balance(balance) do
    %{
      "epoch" => balance.epoch,
      "balance" => to_string(balance.balance),
      "effective_balance" => to_string(balance.effective_balance)
    }
  end

  defp prepare_beacon_withdrawal(withdrawal) do
    %{
      "index" => withdrawal.index,
      "validator_index" => withdrawal.validator_index,
      "address" => to_string(withdrawal.address),
      "amount" => to_string(withdrawal.amount),
      "slot" => withdrawal.slot,
      "epoch" => withdrawal.epoch
    }
  end

  defp prepare_beacon_slashing(slashing) do
    %{
      "slot" => slashing.slot,
      "epoch" => slashing.epoch,
      "slashed_validator_index" => slashing.slashed_validator_index,
      "slasher_validator_index" => slashing.slasher_validator_index,
      "reason" => slashing.reason,
      "details" => slashing.details
    }
  end
end
