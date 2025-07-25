# SHIPS2‑Go × Wazuh Integration Guide

*Forward password/BitLocker‑key retrieval events to your Wazuh SIEM*

---

## 1. Why integrate?

Every time an operator fetches a password or BitLocker recovery key through the SSH wrapper, SHIPS2‑Go logs an audited message via `logger -t shipsc-wrapper`. By forwarding those syslog entries to Wazuh (rule 91000) you can:

- Detect suspicious access patterns (e.g. too many fetches in a short window).
- Correlate credential access with other security alerts on the same host.
- Build dashboards showing who accessed which host, when.

---

## 2. Prerequisites

| Component          | Tested version        |
| ------------------ | --------------------- |
| Debian / Ubuntu    | 12 (Bookworm) / 22.04 |
| rsyslog            | 8.2302                |
| Wazuh manager/node | 4.7                   |

---

## 3. Install helper scripts

Run these on the *SHIPS2‑Go* server **as root**:

```bash
/opt/ships/deploy/deploy_rsyslog_shipsc.sh
/opt/ships/deploy/deploy_wazuh_local_rules.sh
```

What they do:

1. **rsyslog drop‑in** → (`/etc/rsyslog.d/60-shipsc-wrapper.conf`)
   ```
   if $programname == 'shipsc-wrapper' then {
       action(type="omfwd" target="<WAZUH_IP>" template="RSYSLOG_SyslogProtocol23Format" port="514" protocol="tcp")
   }
   & stop
   ```
2. **Wazuh rule** → (`/var/ossec/etc/rules/local_rules.xml`)
   ```xml
   <group name="shipsc-wrapper,syslog,">
     <rule id="91000" level="5">
       <if_sid>100000</if_sid>
       <match>shipsc-wrapper</match>
       <description>SHIPS2-Go credential retrieval</description>
     </rule>
   </group>
   ```
3. Reload both services.

---

## 4. Verifying the pipeline

1. SSH to the server and fetch a password:
   ```bash
   ssh shipscmd@server fetch WIN11-PC01
   ```
2. Check `/var/log/syslog` (or `journalctl -t shipsc-wrapper`) for the entry.
3. On the Wazuh dashboard, go to **Security events →** filter by **Rule 91000**. You should see your fetch record.

---

## 5. Troubleshooting

| Symptom               | Likely cause / fix                                                      |
| --------------------- | ----------------------------------------------------------------------- |
| No logs in Wazuh      | Firewall between server and Wazuh manager; test `nc -vz <WAZUH_IP> 514` |
| Rule 91000 not firing | `local_rules.xml` syntax error → run `/var/ossec/bin/ossec-logtest`     |
| Duplicate events      | Ensure only the **shipsc‑wrapper** logger tag triggers rule 91000       |

---

## 6. Customising the rule level

- Level 5 (default) → triggers e‑mail/dashboard but not critical.
- Raise to **level 10** to escalate to PagerDuty or an on‑call rotation.

---

## 7. Uninstall

```bash
rm /etc/rsyslog.d/60-shipsc-wrapper.conf
sed -i '/shipsc-wrapper/,+7d' /var/ossec/etc/rules/local_rules.xml
systemctl restart rsyslog wazuh-manager
```

---

> **That’s it.** All credential access events are now visible in Wazuh alongside the rest of your logs.

