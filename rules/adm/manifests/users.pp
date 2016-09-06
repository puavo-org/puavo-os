class adm::users {
  include adm

  adm::user {
    'puavo-os':
      uid => 1000;
  }
}
