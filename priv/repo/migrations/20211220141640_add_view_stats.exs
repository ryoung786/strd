defmodule Strd.Repo.Migrations.AddViewStats do
  use Ecto.Migration

  def change do
    alter table(:links) do
      add :view_count, :integer, default: 0
    end
  end
end
