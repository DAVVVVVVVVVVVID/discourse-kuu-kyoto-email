import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class ActivationCodeForm extends Component {
  @tracked errorMessage = null;
  @tracked needsApproval = false;

  @action
  async submit(data) {
    this.errorMessage = null;

    try {
      const result = await ajax("/kuu-kyoto-email/activation-code", {
        type: "POST",
        data: { login: this.args.login, code: data.code },
      });

      if (result.needs_approval) {
        this.needsApproval = true;
      } else {
        // 整页刷新，拿到登录后的会话
        window.location.href = result.redirect_to;
      }
    } catch (error) {
      this.errorMessage = extractError(error);
    }
  }

  @action
  validateCode(name, value, { addError }) {
    if (!/^\d{6}$/.test(value?.trim() ?? "")) {
      addError(name, {
        title: i18n("kuu_kyoto_email.activation_code.code_label"),
        message: i18n("kuu_kyoto_email.activation_code.code_format"),
      });
    }
  }

  <template>
    <div class="kuu-kyoto-email-activation-code">
      {{#if this.needsApproval}}
        <p class="kuu-kyoto-email-activation-code__approval">
          {{i18n "kuu_kyoto_email.activation_code.needs_approval"}}
        </p>
      {{else}}
        {{#if @email}}
          <p class="kuu-kyoto-email-activation-code__sent">
            {{i18n "kuu_kyoto_email.activation_code.sent" email=@email}}
          </p>
        {{/if}}

        <Form @onSubmit={{this.submit}} as |form|>
          <form.Field
            @format="full"
            @name="code"
            @title={{i18n "kuu_kyoto_email.activation_code.code_label"}}
            @validate={{this.validateCode}}
            @validation="required"
            as |field|
          >
            <field.Input
              autocomplete="one-time-code"
              inputmode="numeric"
              maxlength="6"
              placeholder="123456"
            />
          </form.Field>

          {{#if this.errorMessage}}
            <div class="kuu-kyoto-email-activation-code__error" role="alert">
              {{this.errorMessage}}
            </div>
          {{/if}}

          <form.Submit
            class="kuu-kyoto-email-activation-code__submit"
            @label="kuu_kyoto_email.activation_code.submit"
          />
        </Form>
      {{/if}}
    </div>
  </template>
}
