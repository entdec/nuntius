# frozen_string_literal: true

class MemberDrop < ApplicationDrop
  delegate :name, :email, to: :@object

  # What a drop makes to attach, as an app's would (a contract's PDF)
  def card
    {content: "Card of #{@object.name}", filename: "card.txt", content_type: "text/plain"}
  end

  def cards
    [card, {"content" => StringIO.new("Back"), "filename" => "back.txt", "content_type" => "text/plain"}]
  end

  def nothing = nil
end
