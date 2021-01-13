# These aren't expected to be called by a developer. They are internal methods.
module EffectiveDatatablesPrivateHelper

  # https://datatables.net/reference/option/columns
  def datatable_columns(datatable)
    form = nil
    simple_form_for(:datatable_search, url: '#', html: {id: "#{datatable.to_param}-form"}) { |f| form = f }

    datatable.columns.map do |name, opts|
      {
        name: name,
        title: content_tag(:span, (opts[:label] == false ? '' : opts[:label]), class: 'search-label'),
        className: opts[:col_class],
        searchHtml: (datatable_search_html(form, name, datatable.state[:search][name], opts) unless datatable.simple?),
        responsivePriority: opts[:responsive],
        search: datatable.state[:search][name],
        sortable: (opts[:sort] && !datatable.simple?),
        visible: datatable.state[:visible][name],
      }
    end.to_json.html_safe
  end

  def datatable_bulk_actions(datatable)
    if datatable._bulk_actions.present?
      render(partial: '/effective/datatables/bulk_actions_dropdown', locals: { datatable: datatable }).gsub("'", '"').html_safe
    end
  end

  def datatable_reset(datatable)
    render(partial: '/effective/datatables/reset', locals: { datatable: datatable }).gsub("'", '"').html_safe
  end

  def datatable_search_html(form, name, value, opts)
    include_blank = opts[:search].key?(:include_blank) ? opts[:search][:include_blank] : opts[:label]
    pattern = opts[:search][:pattern]
    placeholder = opts[:search][:placeholder] || ''
    title = opts[:search][:title] || opts[:label]
    wrapper_html = { class: 'datatable_search' }

    input_html = {
      name: nil,
      value: value,
      title: title,
      pattern: pattern,
      data: {'column-name' => name, 'column-index' => opts[:index]}
    }.delete_if { |k, v| v.blank? && k != :name }

    case opts[:search][:as]
    when :string, :text, :number
      form.input name, label: false, required: false, value: value,
        as: :string,
        placeholder: placeholder,
        wrapper_html: wrapper_html,
        input_html: input_html
    when :effective_obfuscation
      input_html[:pattern] ||= '[0-9]{3}-?[0-9]{4}-?[0-9]{3}'
      input_html[:title] = 'Expected format: XXX-XXXX-XXX'

      form.input name, label: false, required: false, value: value,
        as: :string,
        placeholder: placeholder,
        wrapper_html: wrapper_html,
        input_html: input_html
    when :date, :datetime
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_date_picker) ? :effective_date_picker : :string),
        placeholder: placeholder,
        wrapper_html: wrapper_html,
        input_group: false,
        input_html: input_html,
        date_linked: false,
        input_js: { useStrict: true, keepInvalid: true }
        # Keep invalid format like "2015-11" so we can still search by year, month or day
    when :time
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_time_picker) ? :effective_time_picker : :string),
        placeholder: placeholder,
        wrapper_html: wrapper_html,
        input_group: false,
        input_html: input_html,
        date_linked: false,
        input_js: { useStrict: false, keepInvalid: true }
    when :select, :boolean
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_select) ? :effective_select : :select),
        collection: opts[:search][:collection],
        selected: opts[:search][:value],
        multiple: opts[:search][:multiple],
        grouped: opts[:search][:grouped],
        polymorphic: opts[:search][:polymorphic],
        template: opts[:search][:template],
        include_blank: include_blank,
        wrapper_html: wrapper_html,
        input_html: input_html,
        input_js: { placeholder: placeholder }
    when :bulk_actions
      input_html[:data]['role'] = 'bulk-actions-all'

      form.input name, label: false, required: false, value: nil,
        as: :boolean,
        input_html: input_html
    end
  end

end
