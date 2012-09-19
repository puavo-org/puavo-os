define [], ->
  [__, org, schoolId] = window.location.pathname.split("/")

  return {
    currentOrg: org
    currentSchoolId: schoolId
    appRoot: "/#{ org }/#{ schoolId }/wlan/"
    newPath: (org, id) -> "/#{ org }/#{ schoolId }/wlan/"
  }
