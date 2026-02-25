# 📘 SFMS Phase 1 DATABASE 설계서 - 도메인간 연결 (Revised v1.3)

* **문서 버전:** v1.3 (Production Ready)
* **작성일:** 2026-02-17
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🗺️ ERD (Entity Relationship Diagram)

```mermaid
erDiagram

    %% =========================================================
    %% 🔗 Cross-Domain Relationships (핵심 연결 고리)
    %% =========================================================
    
    %% 사용자 -> 시스템 로그/알림
    usr_users ||--o{ IAM_user_roles : "has"

    %% 사용자 -> 시스템 로그/알림
    usr_users ||--o{ cmm_audit_logs : "행위 기록 (Actor_user_id)"
    usr_users ||--o{ cmm_notifications : "알림 수신 (Receiver_user_id)"
    
    %% 사용자 -> 프로필 사진
    usr_users ||..|| cmm_attachments : "Soft Link (domain='fac', ref_id=id) 프로필 이미지"
    

    %% (논리적 연결 예시) 시설 -> 첨부파일 (도면 등)
    fac_facilities ||..o{ cmm_attachments : "Soft Link (domain='fac', ref_id=id) 시설관련 도면/문서/사진"
    fac_spaces ||..o{ cmm_attachments : "Soft Link (domain='SPC', ref_id=id) 공간관련 도면/문서/사진"

    %% =========================================================
    %% 🎨 Styling
    %% =========================================================
    classDef cmm fill:#FFF3E0,stroke:#FF9800,stroke-width:2px,color:#000
    classDef usr fill:#E3F2FD,stroke:#2196F3,stroke-width:2px,color:#000
    classDef IAM fill:#F3E5F5,stroke:#9C27B0,stroke-width:2px,color:#000
    classDef fac fill:#E8F5E9,stroke:#4CAF50,stroke-width:2px,color:#000

    class cmm_code_groups,cmm_code_details,cmm_system_domains,cmm_sequence_rules,cmm_attachments,cmm_audit_logs,cmm_notifications cmm
    class usr_organizations,usr_users usr
    class IAM_roles,IAM_user_roles IAM_style
    class facility_categories,fac_facilities,fac_spaces fac

```
