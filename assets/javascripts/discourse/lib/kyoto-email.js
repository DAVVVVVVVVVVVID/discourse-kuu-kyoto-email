import getURL from "discourse/lib/get-url";

// 和 core 的 EmailValidator.email_in_restriction_setting? 一样，子域名也算
export function isKyotoEmail(email, domains) {
  const host = email?.toLowerCase().split("@")[1];
  if (!host || !domains?.length) {
    return false;
  }

  return domains.some((domain) => {
    const lowerDomain = domain.toLowerCase();
    return host === lowerDomain || host.endsWith(`.${lowerDomain}`);
  });
}

export function bindEmailUrl(user) {
  return getURL(`/u/${user.username_lower}/preferences/email?new=1`);
}

export function viewingOwnUserPage(router, currentUser) {
  let route = router.currentRoute;
  while (route && route.name !== "user") {
    route = route.parent;
  }

  return (
    !!currentUser &&
    route?.params?.username?.toLowerCase() === currentUser.username_lower
  );
}
