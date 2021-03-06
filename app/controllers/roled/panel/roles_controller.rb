module Roled
  class Panel::RolesController < Panel::BaseController
    before_action :set_role, only: [
      :show, :overview, :edit, :update, :destroy,
      :namespaces, :governs, :rules,
      :business_on, :business_off, :namespace_on, :namespace_off, :govern_on, :govern_off, :rule_on, :rule_off
    ]

    def index
      @roles = Role.order(created_at: :asc)
    end

    def new
      @role = Role.new
    end

    def create
      @role = Role.new role_params

      unless @role.save
        render :new, locals: { model: @role }, status: :unprocessable_entity
      end
    end

    def show
      q_params = {}
      q_params.merge! params.permit(:govern_taxon_id)

      @governs = Govern.includes(:rules).default_where(q_params)
      @busynesses = Busyness.all
    end

    def namespaces
      @busyness = Busyness.find_by identifier: params[:business_identifier].presence
    end

    def governs
      @name_space = NameSpace.find_by identifier: params[:namespace_identifier].presence
      q_params = {
        business_identifier: nil,
        namespace_identifier: nil,
        allow: { business_identifier: nil, namespace_identifier: nil }
      }
      q_params.merge! params.permit(:business_identifier, :namespace_identifier)

      @governs = Govern.default_where(q_params)
    end

    def rules
      @govern = Govern.find params[:govern_id]

      @rules = @govern.rules
    end

    def overview
      @taxon_ids = @role.governs.unscope(:order).uniq
    end

    def edit
    end

    def business_on
      @busyness = Busyness.find_by identifier: params[:business_identifier].presence
      @role.business_on @busyness

      @role.save
    end

    def business_off
      @busyness = Busyness.find_by identifier: params[:business_identifier].presence
      @role.role_hash.delete params[:business_identifier]
      @role.save
    end

    def namespace_on
      @name_space = NameSpace.find_by identifier: params[:namespace_identifier].presence
      @role.namespace_on(@name_space, params[:business_identifier])
      @role.save

      q_params = {
        business_identifier: nil,
        namespace_identifier: nil,
        allow: { business_identifier: nil, namespace_identifier: nil }
      }
      q_params.merge! params.permit(:business_identifier, :namespace_identifier)

      @governs = Govern.default_where(q_params)
    end

    def namespace_off
      @name_space = NameSpace.find_by identifier: params[:namespace_identifier].presence
      @role.namespace_off(@name_space, params[:business_identifier])
      @role.save

      q_params = {
        business_identifier: nil,
        namespace_identifier: nil,
        allow: { business_identifier: nil, namespace_identifier: nil }
      }
      q_params.merge! params.permit(:business_identifier, :namespace_identifier)

      @governs = Govern.default_where(q_params)
    end

    def govern_on
      @govern = Govern.find params[:govern_id]
      @role.govern_on(@govern)
      @role.save
    end

    def govern_off
      @govern = Govern.find params[:govern_id]
      @role.govern_off(@govern)
      @role.save
    end

    def rule_on
      @rule = Rule.find params[:rule_id]

      @role.role_hash.deep_merge!(@rule.business_identifier.to_s => {
        @rule.namespace_identifier.to_s => {
          @rule.controller_path => {
            @rule.action_name => true
          }
        }
      })
      @role.save
    end

    def rule_off
      @rule = Rule.find params[:rule_id]

      @role.role_hash.fetch(@rule.business_identifier.to_s, {}).fetch(@rule.namespace_identifier.to_s, {}).fetch(@rule.controller_path, {}).delete(@rule.action_name)
      @role.save
    end

    def update
      @role.assign_attributes role_params

      unless @role.save
        render :edit, locals: { model: @role }, status: :unprocessable_entity
      end
    end

    def destroy
      @role.destroy
    end

    private
    def role_params
      p = params.fetch(:role, {}).permit(
        :name,
        :code,
        :description,
        :visible,
        :default,
        who_types: []
      )
      p.fetch(:who_types, []).reject!(&:blank?)
      p
    end

    def set_role
      @role = Role.find params[:id]
    end

  end
end
