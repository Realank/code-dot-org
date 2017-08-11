require 'digest/md5'
require_relative '../../deployment'
require lib_dir 'forms/pegasus_form_validation'

include PegasusFormValidation

# Deletes a form from the DB and from SOLR.
# @param [String] kind The kind of form to delete.
# @param [String] secret The secret associated with the form to delete.
# @return [Boolean] Whether the form was deleted.
def delete_form(kind, secret)
  form = DB[:forms].where(kind: kind, secret: secret).first
  return false unless form

  DB[:forms].where(id: form[:id]).delete
  Solr::Server.new(host: CDO.solr_server).delete_by_id(form[:id]) if CDO.solr_server

  true
end

# Inserts or upserts a form (depending on its kind) into the DB.
# @param [String] kind The kind of form to insert.
# @param [Hash] data The data with which to populate the form.
# @param [Hash] options Default {}.
#   @option [Integer] :parent_id The ID of the parent form.
# TODO(asher): Fix this method, both the naming of it (to indicate the upsert behavior) and its
# implementation (not overwriting various fields on update).
def insert_or_upsert_form(kind, data, options={})
  if dashboard_user
    data[:email_s] ||= dashboard_user[:email]
    data[:name_s] ||= dashboard_user[:name]
  end

  data = validate_form(kind, data, Pegasus.logger)

  timestamp = DateTime.now

  normalized_email = data[:email_s].to_s.strip.downcase
  row = {
    secret: SecureRandom.hex,
    parent_id: options[:parent_id],
    email: normalized_email,
    name: data[:name_s].to_s.strip,
    kind: kind,
    data: data.to_json,
    created_at: timestamp,
    created_ip: request.ip,
    updated_at: timestamp,
    updated_ip: request.ip,
    hashed_email: Digest::MD5.hexdigest(normalized_email),
  }
  row[:user_id] = dashboard_user ? dashboard_user[:id] : data[:user_id_i]

  form_class = Object.const_get(kind)
  row[:source_id] = form_class.get_source_id(data) if form_class.respond_to? :get_source_id

  # Depending on the form kind, new data, and existing data, perform an update.
  existing_form_secret = form_class.update_on_upsert row
  if existing_form_secret
    return update_form(row[:kind], existing_form_secret, row)
  end

  # We didn't perform an update, so insert the row into the forms table and
  # create a corresponding form_geos row.
  row[:id] = DB[:forms].insert(row)

  form_geos_row = {
    form_id: row[:id],
    created_at: timestamp,
    updated_at: timestamp,
    ip_address: request.ip
  }
  DB[:form_geos].insert(form_geos_row)

  row
end

# WARNING: This method only updates certain fields.
# @param [String] kind The kind of the form to be updated.
# @param [String] secret The secret associated with the form to be updated.
# @param [Hash] data The data to update.
# @return [Hash] The hash of values sent to the DB for updating.
def update_form(kind, secret, data)
  return nil unless form = DB[:forms].where(kind: kind, secret: secret).first

  if dashboard_user && !dashboard_user[:admin]
    data[:email_s] ||= dashboard_user[:email]
    data[:name_s] ||= dashboard_user[:name]
  end

  prev_data = JSON.parse(form[:data], symbolize_names: true)
  symbolized_data = Hash[data.map {|k, v| [k.to_sym, v]}]
  if symbolized_data[:data]
    symbolized_data.merge!(Hash[JSON.parse(symbolized_data[:data]).map {|k, v| [k.to_sym, v]}])
  end
  data = validate_form(kind, prev_data.merge(symbolized_data), Pegasus.logger)

  normalized_email = data[:email_s].to_s.strip.downcase if data.key?(:email_s)

  form[:user_id] = dashboard_user[:id] if dashboard_user && !dashboard_user[:admin]
  form[:email] = normalized_email
  form[:name] = data[:name_s].to_s.strip if data.key?(:name_s)
  form[:data] = data.to_json
  form[:updated_at] = DateTime.now
  form[:updated_ip] = request.ip
  form[:processed_at] = nil
  form[:indexed_at] = nil
  form[:review] = nil
  form[:reviewed_at] = nil
  form[:reviewed_by] = nil
  form[:reviewed_ip] = nil
  form[:hashed_email] = Digest::MD5.hexdigest(normalized_email) if data.key?(:email_s)
  DB[:forms].where(id: form[:id]).update(form)

  form
end
