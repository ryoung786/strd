defmodule Strd.Repo.Migrations.CreateLinks do
  use Ecto.Migration

  def change do
    create table(:links) do
      add :original, :string, size: 512, null: false
      add :short, :string, size: 6, null: false

      timestamps()
    end

    create unique_index(:links, [:short])
  end
end
