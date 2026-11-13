# Nuntius 2.0: LMTP is a provider on the :mail transport instead of a
# transport of its own. Mail to an LMTP address (<email>@<host>:<port>) goes
# to it, other mail to SMTP (see BaseProvider.handles?).
#
# Templates, campaigns and messages with the :lmtp transport get :mail. A
# template's transport is part of the scope its translations are in, so they
# move along (see Translations.move).
class MoveNuntiusLmtpToMail < ActiveRecord::Migration[8.1]
  def up
    Nuntius::Template.where(transport: "lmtp").find_each do |template|
      before = template.translation_scope
      template.update_column(:transport, "mail")
      Nuntius::Translations.move(template.account_id, before, template.translation_scope)
    end
    execute "UPDATE nuntius_campaigns SET transport = 'mail' WHERE transport = 'lmtp'"
    execute "UPDATE nuntius_messages SET transport = 'mail' WHERE transport = 'lmtp'"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
