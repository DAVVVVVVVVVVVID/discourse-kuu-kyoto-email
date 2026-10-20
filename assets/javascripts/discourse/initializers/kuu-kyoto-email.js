import { action } from "@ember/object";
import EmailDropdown from "discourse/components/email-dropdown";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";
import AccountCreatedActivationCode from "../components/kuu-kyoto-email/account-created-activation-code";
import AdminUserKyotoEmail from "../components/kuu-kyoto-email/admin-user-kyoto-email";
import NotActivated from "../components/kuu-kyoto-email/modal/not-activated";
import PreferencesKyotoEmail from "../components/kuu-kyoto-email/preferences-kyoto-email";
import ReminderBanner from "../components/kuu-kyoto-email/reminder-banner";
import SignupHint from "../components/kuu-kyoto-email/signup-hint";
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
      api.renderInOutlet("above-main-container", AccountCreatedActivationCode);
      api.renderInOutlet("above-main-container", ReminderBanner);
      api.renderInOutlet(
        "user-preferences-account-after-email",
        PreferencesKyotoEmail
      );
      api.renderInOutlet("admin-user-below-names", AdminUserKyotoEmail);
      api.renderInOutlet("create-account-after-email", SignupHint);
      api.renderInOutlet("code-login-email-step-fields", SignupHint);

      if (siteSettings.kuu_kyoto_email_activation_code_enabled) {
        const showNotActivated = (Superclass) =>
          class extends Superclass {
            @action
            showNotActivated(props) {
              if (
                !isKyotoEmail(props.currentEmail, site.kuu_kyoto_email_domains)
              ) {
                return super.showNotActivated(props);
              }

              container
                .lookup("service:modal")
                .show(NotActivated, { model: props });
            }
          };
        api.modifyClass("controller:login", showNotActivated);
        api.modifyClass("route:application", showNotActivated);
      }

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
