import EmailDropdown from "discourse/components/email-dropdown";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";
import AdminUserKyotoEmail from "../components/kuu-kyoto-email/admin-user-kyoto-email";
import PreferencesEmailNote from "../components/kuu-kyoto-email/preferences-email-note";
import ReminderBanner from "../components/kuu-kyoto-email/reminder-banner";
import { isKyotoEmail, viewingOwnUserPage } from "../lib/kyoto-email";

export default {
  name: "kuu-kyoto-email",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.kuu_kyoto_email_enabled) {
      return;
    }

    const currentUser = container.lookup("service:current-user");
    const router = container.lookup("service:router");
    const site = container.lookup("service:site");

    withPluginApi((api) => {
      api.renderInOutlet("above-main-container", ReminderBanner);
      api.renderInOutlet(
        "user-preferences-account-after-email",
        PreferencesEmailNote
      );
      api.renderInOutlet("admin-user-below-names", AdminUserKyotoEmail);

      // 锁只对本人生效，管理员在别人的偏好设置里看到的菜单不变；后端同样会拦
      api.modifySelectKit("dropdown-select-box").replaceContent((component) => {
        if (
          !(component instanceof EmailDropdown) ||
          !currentUser?.kuu_kyoto_email_status ||
          !viewingOwnUserPage(router, currentUser) ||
          !isKyotoEmail(component.email?.email, site.kuu_kyoto_email_domains)
        ) {
          return;
        }

        return [
          {
            id: "kuuKyotoEmailLocked",
            icon: "lock",
            name: i18n("kuu_kyoto_email.preferences.locked"),
            description: "",
          },
        ];
      });
    });
  },
};
