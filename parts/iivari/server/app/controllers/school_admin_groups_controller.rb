class SchoolAdminGroupsController < ApplicationController
  filter_access_to :all, :attribute_check => false

  # GET /:school_id/admins
  def index
    admin_group_ids = SchoolAdminGroup.find_all_by_school_id(params[:school_id]).map{ |g| g.group_id }
    @current_admin_groups = []
    @available_groups = []
    puavo_api.groups.all.each do |group|
      if admin_group_ids.include?(group.puavo_id)
        @current_admin_groups.push group
      else
        @available_groups.push group
      end
    end

    @schools_by_id = {}
    puavo_api.schools.all.each do |school|
      @schools_by_id[school.puavo_id] = school
    end

  end

  # PUT /:school_id/admins/:group_id
  def add_group
    SchoolAdminGroup.create(:school_id => @school.puavo_id,
                            :group_id => params[:group_id])

    respond_to do |format|
      format.html { redirect_to school_admin_groups_path }
    end
  end

  # DELETE /:school_id/admins/:group_id
  def delete_group
    @sag = SchoolAdminGroup.where(:school_id => @school.puavo_id,
                                  :group_id => params[:group_id]).first
    @sag.destroy

    respond_to do |format|
      format.html { redirect_to school_admin_groups_path }
    end
  end

end
