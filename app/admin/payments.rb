ActiveAdmin.register Payment do
  actions :all, except: [:edit]
  
  filter :reference
  filter :price_cents
  filter :status
  filter :payment_method
  filter :created_at
  
  index do
    selectable_column
    id_column
    column :reference
    column :user_id
    column :price
    column :status
    column :payment_method
    column :created_at
    actions
  end
  
  show do
    attributes_table do
      row :reference
      row :price
      row :status
      row :payment_method
      row :user
      row :created_at
      row :response_id
      row :full_response
    end
    active_admin_comments
  end
  
  action_item :refund, only: :show do
    link_to("Refund Payment",
      refunds_path(id: payment.id, type: Payment),
      method: "POST",
      class: "button",
      data: {confirm: "Are you sure you want to refund this payment?"})
  end
end
