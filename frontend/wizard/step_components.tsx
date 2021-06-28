import React from "react";
import { t } from "../i18next_wrapper";
import { Row, Col } from "../ui";
import { FirmwareNumberSettingsProps } from "./interfaces";
import { sourceFwConfigValue } from "../settings/source_config_value";
import { validFwConfig } from "../util";
import { getFbosConfig, getFirmwareConfig } from "../resources/getters";
import { getFwHardwareValue } from "../settings/firmware/firmware_hardware_support";
import { McuInputBox } from "../settings/hardware_settings/mcu_input_box";

export class Video extends React.Component<{ url: string }> {
  shouldComponentUpdate = () => false;
  render() {
    const { url } = this.props;
    return <iframe key={url} src={url + "&cc_load_policy=1"}
      frameBorder={0} width={"100%"} allowFullScreen={true} />;
  }
}

export const FirmwareNumberSettings = (props: FirmwareNumberSettingsProps) =>
  <div className={"motor-settings"}>
    {props.firmwareNumberSettings?.map(setting =>
      <Row key={setting.key}>
        <Col xs={6}>
          <label>{t(setting.label)}</label>
        </Col>
        <Col xs={6}>
          <McuInputBox
            dispatch={props.dispatch}
            sourceFwConfig={sourceFwConfigValue(
              validFwConfig(getFirmwareConfig(props.resources)),
              props.bot.hardware.mcu_params)}
            firmwareHardware={getFwHardwareValue(getFbosConfig(
              props.resources))}
            setting={setting.key} />
        </Col>
      </Row>)}
  </div>;
