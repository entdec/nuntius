# frozen_string_literal: true

json.selector "ul.attachments"
json.html render partial: "nuntius/admin/layouts/attachments/attachments", layout: false, formats: [:html],
  locals: {attachments: @layout.attachments, upload_url: admin_layout_attachments_path(@layout)}
