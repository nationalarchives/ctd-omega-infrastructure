locals {
    clean_ipv6_address = "${
        replace(
            replace(
                replace(
                    replace(
                        var.ipv6_address,
                        "/^([^/]+)(?:/[0-9]+)?/",
                        "$1"
                    ),
                    "/(?::([0-9]):)|(?:^([0-9]):)|(?::([0-9])$)/",
                    "000$1"
                ),
                "/(?::([0-9]{2}):)|(?:^([0-9]{2}):)|(?::([0-9]{2})$)/",
                "00$1"
            ),
            "(?::([0-9]{3}):)|(?:^([0-9]{3}):)|(?::([0-9]{3})$)",
            "0$1"
        )
    }"

    ipv6_address_list = split(":", local.clean_ipv6_address)

    reverse_ipv6_address_list = reverse(local.ipv6_address_list)

    reverse_ipv6_address_list_segments = split("",
            replace(
                strrev(local.clean_ipv6_address),
                ":",
                ""
            )
    )
}
