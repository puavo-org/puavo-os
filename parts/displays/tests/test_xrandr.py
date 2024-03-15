"""
Test puavodisplays.xrandr
"""

import puavodisplays.xrandr


def _read_prop(file_path: str) -> str:
    with open(file_path, encoding="utf-8") as xrandr_prop_output_file:
        return xrandr_prop_output_file.read()


def test_prop_parser():
    xrandr_prop_output = _read_prop("xrandr_prop_output_1_display.txt")
    parser = (
        puavodisplays.xrandr._XRandrPropOutputParser()  # pylint: disable=protected-access
    )
    prop = parser.parse(xrandr_prop_output)

    assert prop == {
        "eDP-1": {
            "name": "eDP-1",
            "state": "connected",
            "props": {
                "_MUTTER_PRESENTATION_OUTPUT": {
                    "name": "_MUTTER_PRESENTATION_OUTPUT",
                    "value": "0",
                },
                "EDID": {
                    "name": "EDID",
                    "value": "00ffffffffffff0009e5f30700000000011c0104a5221378037b80a6544d9b26115054000000010101010101010101010101010101014dd000a0f0703e803020a50058c21000001ae08a00a0f0703e803020a50058c21000001a00000000000000000000000000000000000000000002000a29ff0f3cc823123cc800000000ea",
                },
                "scaling mode": {
                    "name": "scaling mode",
                    "value": "Full aspect",
                    "supported_values": ["Full", "Center", "Full aspect"],
                },
                "Colorspace": {
                    "name": "Colorspace",
                    "value": "Default",
                    "supported_values": [
                        "Default",
                        "RGB_Wide_Gamut_Fixed_Point",
                        "RGB_Wide_Gamut_Floating_Point",
                        "opRGB",
                        "DCI-P3_RGB_D65",
                        "BT2020_RGB",
                        "BT601_YCC",
                        "BT709_YCC",
                        "XVYCC_601",
                        "XVYCC_709",
                        "SYCC_601",
                        "opYCC_601",
                        "BT2020_CYCC",
                        "BT2020_YCC",
                    ],
                },
                "max bpc": {
                    "name": "max bpc",
                    "value": 12,
                    "value_min": 6,
                    "value_max": 12,
                },
                "Broadcast RGB": {
                    "name": "Broadcast RGB",
                    "value": "Automatic",
                    "supported_values": ["Automatic", "Full", "Limited 16:235"],
                },
                "panel orientation": {
                    "name": "panel orientation",
                    "value": "Normal",
                    "supported_values": [
                        "Normal",
                        "Upside Down",
                        "Left Side Up",
                        "Right Side Up",
                    ],
                },
                "link-status": {
                    "name": "link-status",
                    "value": "Good",
                    "supported_values": ["Good", "Bad"],
                },
                "CTM": {"name": "CTM", "value": "0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 00 1"},
                "CONNECTOR_ID": {
                    "name": "CONNECTOR_ID",
                    "value": "95",
                    "supported_values": ["95"],
                },
                "non-desktop": {
                    "name": "non-desktop",
                    "value": 0,
                    "value_min": 0,
                    "value_max": 1,
                },
            },
        },
        "DP-1": {
            "name": "DP-1",
            "state": "disconnected",
            "props": {
                "HDCP Content Type": {
                    "name": "HDCP Content Type",
                    "value": "HDCP Type0",
                    "supported_values": ["HDCP Type0", "HDCP Type1"],
                },
                "Content Protection": {
                    "name": "Content Protection",
                    "value": "Undesired",
                    "supported_values": ["Undesired", "Desired", "Enabled"],
                },
                "Colorspace": {
                    "name": "Colorspace",
                    "value": "Default",
                    "supported_values": [
                        "Default",
                        "RGB_Wide_Gamut_Fixed_Point",
                        "RGB_Wide_Gamut_Floating_Point",
                        "opRGB",
                        "DCI-P3_RGB_D65",
                        "BT2020_RGB",
                        "BT601_YCC",
                        "BT709_YCC",
                        "XVYCC_601",
                        "XVYCC_709",
                        "SYCC_601",
                        "opYCC_601",
                        "BT2020_CYCC",
                        "BT2020_YCC",
                    ],
                },
                "max bpc": {
                    "name": "max bpc",
                    "value": 12,
                    "value_min": 6,
                    "value_max": 12,
                },
                "Broadcast RGB": {
                    "name": "Broadcast RGB",
                    "value": "Automatic",
                    "supported_values": ["Automatic", "Full", "Limited 16:235"],
                },
                "audio": {
                    "name": "audio",
                    "value": "auto",
                    "supported_values": ["force-dvi", "off", "auto", "on"],
                },
                "subconnector": {
                    "name": "subconnector",
                    "value": "Unknown",
                    "supported_values": [
                        "Unknown",
                        "VGA",
                        "DVI-D",
                        "HDMI",
                        "DP",
                        "Wireless",
                        "Native",
                    ],
                },
                "link-status": {
                    "name": "link-status",
                    "value": "Good",
                    "supported_values": ["Good", "Bad"],
                },
                "CTM": {"name": "CTM", "value": "0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 00 1"},
                "CONNECTOR_ID": {
                    "name": "CONNECTOR_ID",
                    "value": "103",
                    "supported_values": ["103"],
                },
                "non-desktop": {
                    "name": "non-desktop",
                    "value": 0,
                    "value_min": 0,
                    "value_max": 1,
                },
            },
        },
        "HDMI-1": {
            "name": "HDMI-1",
            "state": "disconnected",
            "props": {
                "HDCP Content Type": {
                    "name": "HDCP Content Type",
                    "value": "HDCP Type0",
                    "supported_values": ["HDCP Type0", "HDCP Type1"],
                },
                "Content Protection": {
                    "name": "Content Protection",
                    "value": "Undesired",
                    "supported_values": ["Undesired", "Desired", "Enabled"],
                },
                "max bpc": {
                    "name": "max bpc",
                    "value": 12,
                    "value_min": 8,
                    "value_max": 12,
                },
                "content type": {
                    "name": "content type",
                    "value": "No Data",
                    "supported_values": [
                        "No Data",
                        "Graphics",
                        "Photo",
                        "Cinema",
                        "Game",
                    ],
                },
                "Colorspace": {
                    "name": "Colorspace",
                    "value": "Default",
                    "supported_values": [
                        "Default",
                        "SMPTE_170M_YCC",
                        "BT709_YCC",
                        "XVYCC_601",
                        "XVYCC_709",
                        "SYCC_601",
                        "opYCC_601",
                        "opRGB",
                        "BT2020_CYCC",
                        "BT2020_RGB",
                        "BT2020_YCC",
                        "DCI-P3_RGB_D65",
                        "DCI-P3_RGB_Theater",
                    ],
                },
                "aspect ratio": {
                    "name": "aspect ratio",
                    "value": "Automatic",
                    "supported_values": ["Automatic", "4:3", "16:9"],
                },
                "Broadcast RGB": {
                    "name": "Broadcast RGB",
                    "value": "Automatic",
                    "supported_values": ["Automatic", "Full", "Limited 16:235"],
                },
                "audio": {
                    "name": "audio",
                    "value": "auto",
                    "supported_values": ["force-dvi", "off", "auto", "on"],
                },
                "link-status": {
                    "name": "link-status",
                    "value": "Good",
                    "supported_values": ["Good", "Bad"],
                },
                "CTM": {"name": "CTM", "value": "0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 00 1"},
                "CONNECTOR_ID": {
                    "name": "CONNECTOR_ID",
                    "value": "113",
                    "supported_values": ["113"],
                },
                "non-desktop": {
                    "name": "non-desktop",
                    "value": 0,
                    "value_min": 0,
                    "value_max": 1,
                },
            },
        },
        "DP-2": {
            "name": "DP-2",
            "state": "disconnected",
            "props": {
                "HDCP Content Type": {
                    "name": "HDCP Content Type",
                    "value": "HDCP Type0",
                    "supported_values": ["HDCP Type0", "HDCP Type1"],
                },
                "Content Protection": {
                    "name": "Content Protection",
                    "value": "Undesired",
                    "supported_values": ["Undesired", "Desired", "Enabled"],
                },
                "Colorspace": {
                    "name": "Colorspace",
                    "value": "Default",
                    "supported_values": [
                        "Default",
                        "RGB_Wide_Gamut_Fixed_Point",
                        "RGB_Wide_Gamut_Floating_Point",
                        "opRGB",
                        "DCI-P3_RGB_D65",
                        "BT2020_RGB",
                        "BT601_YCC",
                        "BT709_YCC",
                        "XVYCC_601",
                        "XVYCC_709",
                        "SYCC_601",
                        "opYCC_601",
                        "BT2020_CYCC",
                        "BT2020_YCC",
                    ],
                },
                "max bpc": {
                    "name": "max bpc",
                    "value": 12,
                    "value_min": 6,
                    "value_max": 12,
                },
                "Broadcast RGB": {
                    "name": "Broadcast RGB",
                    "value": "Automatic",
                    "supported_values": ["Automatic", "Full", "Limited 16:235"],
                },
                "audio": {
                    "name": "audio",
                    "value": "auto",
                    "supported_values": ["force-dvi", "off", "auto", "on"],
                },
                "subconnector": {
                    "name": "subconnector",
                    "value": "Unknown",
                    "supported_values": [
                        "Unknown",
                        "VGA",
                        "DVI-D",
                        "HDMI",
                        "DP",
                        "Wireless",
                        "Native",
                    ],
                },
                "link-status": {
                    "name": "link-status",
                    "value": "Good",
                    "supported_values": ["Good", "Bad"],
                },
                "CTM": {"name": "CTM", "value": "0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 00 1"},
                "CONNECTOR_ID": {
                    "name": "CONNECTOR_ID",
                    "value": "119",
                    "supported_values": ["119"],
                },
                "non-desktop": {
                    "name": "non-desktop",
                    "value": 0,
                    "value_min": 0,
                    "value_max": 1,
                },
            },
        },
        "HDMI-2": {
            "name": "HDMI-2",
            "state": "disconnected",
            "props": {
                "HDCP Content Type": {
                    "name": "HDCP Content Type",
                    "value": "HDCP Type0",
                    "supported_values": ["HDCP Type0", "HDCP Type1"],
                },
                "Content Protection": {
                    "name": "Content Protection",
                    "value": "Undesired",
                    "supported_values": ["Undesired", "Desired", "Enabled"],
                },
                "max bpc": {
                    "name": "max bpc",
                    "value": 12,
                    "value_min": 8,
                    "value_max": 12,
                },
                "content type": {
                    "name": "content type",
                    "value": "No Data",
                    "supported_values": [
                        "No Data",
                        "Graphics",
                        "Photo",
                        "Cinema",
                        "Game",
                    ],
                },
                "Colorspace": {
                    "name": "Colorspace",
                    "value": "Default",
                    "supported_values": [
                        "Default",
                        "SMPTE_170M_YCC",
                        "BT709_YCC",
                        "XVYCC_601",
                        "XVYCC_709",
                        "SYCC_601",
                        "opYCC_601",
                        "opRGB",
                        "BT2020_CYCC",
                        "BT2020_RGB",
                        "BT2020_YCC",
                        "DCI-P3_RGB_D65",
                        "DCI-P3_RGB_Theater",
                    ],
                },
                "aspect ratio": {
                    "name": "aspect ratio",
                    "value": "Automatic",
                    "supported_values": ["Automatic", "4:3", "16:9"],
                },
                "Broadcast RGB": {
                    "name": "Broadcast RGB",
                    "value": "Automatic",
                    "supported_values": ["Automatic", "Full", "Limited 16:235"],
                },
                "audio": {
                    "name": "audio",
                    "value": "auto",
                    "supported_values": ["force-dvi", "off", "auto", "on"],
                },
                "link-status": {
                    "name": "link-status",
                    "value": "Good",
                    "supported_values": ["Good", "Bad"],
                },
                "CTM": {"name": "CTM", "value": "0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 00 1"},
                "CONNECTOR_ID": {
                    "name": "CONNECTOR_ID",
                    "value": "125",
                    "supported_values": ["125"],
                },
                "non-desktop": {
                    "name": "non-desktop",
                    "value": 0,
                    "value_min": 0,
                    "value_max": 1,
                },
            },
        },
        "DP-3": {
            "name": "DP-3",
            "state": "disconnected",
            "props": {
                "HDCP Content Type": {
                    "name": "HDCP Content Type",
                    "value": "HDCP Type0",
                    "supported_values": ["HDCP Type0", "HDCP Type1"],
                },
                "Content Protection": {
                    "name": "Content Protection",
                    "value": "Undesired",
                    "supported_values": ["Undesired", "Desired", "Enabled"],
                },
                "Colorspace": {
                    "name": "Colorspace",
                    "value": "Default",
                    "supported_values": [
                        "Default",
                        "RGB_Wide_Gamut_Fixed_Point",
                        "RGB_Wide_Gamut_Floating_Point",
                        "opRGB",
                        "DCI-P3_RGB_D65",
                        "BT2020_RGB",
                        "BT601_YCC",
                        "BT709_YCC",
                        "XVYCC_601",
                        "XVYCC_709",
                        "SYCC_601",
                        "opYCC_601",
                        "BT2020_CYCC",
                        "BT2020_YCC",
                    ],
                },
                "max bpc": {
                    "name": "max bpc",
                    "value": 12,
                    "value_min": 6,
                    "value_max": 12,
                },
                "Broadcast RGB": {
                    "name": "Broadcast RGB",
                    "value": "Automatic",
                    "supported_values": ["Automatic", "Full", "Limited 16:235"],
                },
                "audio": {
                    "name": "audio",
                    "value": "auto",
                    "supported_values": ["force-dvi", "off", "auto", "on"],
                },
                "subconnector": {
                    "name": "subconnector",
                    "value": "Unknown",
                    "supported_values": [
                        "Unknown",
                        "VGA",
                        "DVI-D",
                        "HDMI",
                        "DP",
                        "Wireless",
                        "Native",
                    ],
                },
                "link-status": {
                    "name": "link-status",
                    "value": "Good",
                    "supported_values": ["Good", "Bad"],
                },
                "CTM": {"name": "CTM", "value": "0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 00 1"},
                "CONNECTOR_ID": {
                    "name": "CONNECTOR_ID",
                    "value": "129",
                    "supported_values": ["129"],
                },
                "non-desktop": {
                    "name": "non-desktop",
                    "value": 0,
                    "value_min": 0,
                    "value_max": 1,
                },
            },
        },
        "HDMI-3": {
            "name": "HDMI-3",
            "state": "disconnected",
            "props": {
                "HDCP Content Type": {
                    "name": "HDCP Content Type",
                    "value": "HDCP Type0",
                    "supported_values": ["HDCP Type0", "HDCP Type1"],
                },
                "Content Protection": {
                    "name": "Content Protection",
                    "value": "Undesired",
                    "supported_values": ["Undesired", "Desired", "Enabled"],
                },
                "max bpc": {
                    "name": "max bpc",
                    "value": 12,
                    "value_min": 8,
                    "value_max": 12,
                },
                "content type": {
                    "name": "content type",
                    "value": "No Data",
                    "supported_values": [
                        "No Data",
                        "Graphics",
                        "Photo",
                        "Cinema",
                        "Game",
                    ],
                },
                "Colorspace": {
                    "name": "Colorspace",
                    "value": "Default",
                    "supported_values": [
                        "Default",
                        "SMPTE_170M_YCC",
                        "BT709_YCC",
                        "XVYCC_601",
                        "XVYCC_709",
                        "SYCC_601",
                        "opYCC_601",
                        "opRGB",
                        "BT2020_CYCC",
                        "BT2020_RGB",
                        "BT2020_YCC",
                        "DCI-P3_RGB_D65",
                        "DCI-P3_RGB_Theater",
                    ],
                },
                "aspect ratio": {
                    "name": "aspect ratio",
                    "value": "Automatic",
                    "supported_values": ["Automatic", "4:3", "16:9"],
                },
                "Broadcast RGB": {
                    "name": "Broadcast RGB",
                    "value": "Automatic",
                    "supported_values": ["Automatic", "Full", "Limited 16:235"],
                },
                "audio": {
                    "name": "audio",
                    "value": "auto",
                    "supported_values": ["force-dvi", "off", "auto", "on"],
                },
                "link-status": {
                    "name": "link-status",
                    "value": "Good",
                    "supported_values": ["Good", "Bad"],
                },
                "CTM": {"name": "CTM", "value": "0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 00 1"},
                "CONNECTOR_ID": {
                    "name": "CONNECTOR_ID",
                    "value": "135",
                    "supported_values": ["135"],
                },
                "non-desktop": {
                    "name": "non-desktop",
                    "value": 0,
                    "value_min": 0,
                    "value_max": 1,
                },
            },
        },
    }
