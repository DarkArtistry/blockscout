defmodule Explorer.Repo.Migrations.AddBeaconValidatorTables do
  use Ecto.Migration

  def change do
    # Beacon validators table
    create table(:beacon_validators, primary_key: false) do
      add(:index, :bigint, primary_key: true, null: false)
      add(:pubkey, :string, size: 98, null: false)
      add(:withdrawal_credentials, :string, size: 66)
      add(:effective_balance, :numeric, precision: 100)
      add(:slashed, :boolean, default: false, null: false)
      add(:activation_eligibility_epoch, :bigint)
      add(:activation_epoch, :bigint)
      add(:exit_epoch, :bigint)
      add(:withdrawable_epoch, :bigint)
      add(:status, :string, size: 30, null: false)
      add(:last_attestation_slot, :bigint)

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(unique_index(:beacon_validators, [:pubkey]))
    create(index(:beacon_validators, [:status]))
    create(index(:beacon_validators, [:slashed]))
    create(index(:beacon_validators, [:activation_epoch]))
    create(index(:beacon_validators, [:exit_epoch]))

    # Beacon validator balances history table
    create table(:beacon_validator_balances, primary_key: false) do
      add(:validator_index, :bigint, null: false)
      add(:epoch, :bigint, null: false)
      add(:balance, :numeric, precision: 100, null: false)
      add(:effective_balance, :numeric, precision: 100, null: false)

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(unique_index(:beacon_validator_balances, [:validator_index, :epoch]))
    create(index(:beacon_validator_balances, [:validator_index]))
    create(index(:beacon_validator_balances, [:epoch]))

    # Beacon attestations table
    create table(:beacon_attestations, primary_key: false) do
      add(:slot, :bigint, null: false)
      add(:committee_index, :bigint, null: false)
      add(:aggregation_bits, :bytea)
      add(:beacon_block_root, :string, size: 66, null: false)
      add(:source_epoch, :bigint, null: false)
      add(:source_root, :string, size: 66, null: false)
      add(:target_epoch, :bigint, null: false)
      add(:target_root, :string, size: 66, null: false)

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(unique_index(:beacon_attestations, [:slot, :committee_index]))
    create(index(:beacon_attestations, [:beacon_block_root]))
    create(index(:beacon_attestations, [:target_epoch]))

    # Beacon slashings table
    create table(:beacon_slashings) do
      add(:slot, :bigint, null: false)
      add(:epoch, :bigint, null: false)
      add(:slashed_validator_index, :bigint, null: false)
      add(:slasher_validator_index, :bigint)
      add(:reason, :string, size: 50, null: false)
      add(:details, :text)

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(index(:beacon_slashings, [:slashed_validator_index]))
    create(index(:beacon_slashings, [:epoch]))
    create(index(:beacon_slashings, [:slot]))

    # Beacon withdrawals table
    create table(:beacon_withdrawals) do
      add(:index, :bigint, null: false)
      add(:validator_index, :bigint, null: false)
      add(:address, :bytea, null: false)
      add(:amount, :numeric, precision: 100, null: false)
      add(:slot, :bigint)
      add(:epoch, :bigint)

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(unique_index(:beacon_withdrawals, [:index]))
    create(index(:beacon_withdrawals, [:validator_index]))
    create(index(:beacon_withdrawals, [:address]))
    create(index(:beacon_withdrawals, [:slot]))
    create(index(:beacon_withdrawals, [:epoch]))
  end
end
