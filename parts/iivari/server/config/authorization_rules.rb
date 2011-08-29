
authorization do
  role :organisation_owner do
    has_permission_on :channels, :to => :manage
    has_permission_on :slides, :to => :manage
  end

  role :school_admin do
    has_permission_on :channels, :to => :manage do
      if_attribute :school_id => is_in {user.admin_of_schools}
    end
    has_permission_on :slides, :to => :manage do
      if_attribute :school_id => is_in {user.admin_of_schools}
    end
  end
end

privileges do
  privilege :manage do
    includes :create, :read, :update, :destroy, :new
  end
  privilege :read do
    includes :index, :show
  end
end
