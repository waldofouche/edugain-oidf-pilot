
# OpenID Federation Test Cases

This document defines test cases for OpenID Federation in eduGAIN. This includes interoprability tests for Trust Anchors, Relying Party's, and OpenID Providers. 

---

## Test Preconditions and Dependencies

| Ref | Area | Preconditions / Dependencies |
|------|------|-------------------------------| 
| **P-01** | Federation Entities | Valid OP and RP federation entity configurations are available, each with correct metadata and signing keys. |
| **P-02** | Trust Anchor Endpoints | The TA exposes `/fetch`, `/list`, and `/resolve` endpoints per OpenID Federation specification. |
| **P-03** | Network & Authentication | All components (TA, OP, RP) can communicate over HTTPS. |
| **P-04** | Trust Marks | Trust mark issuers and validation endpoints are available and reachable. |
| **P-05** | Logging & Monitoring | Logging enabled on TA, OP, and RP components to record enrolment, key, and trust evaluation events. |


## Test Architectures

| Ref | Type | Topology & Description |
|------|-----------|-------------------------------|
| **TA-01** | Basic | A single Trust Anchor managing enrolment and trust for one OP and one RP. |
| **TA-02** | Hierarchical Single-Root | A root Trust Anchor delegates trust to a single intermediate authority, which manages one OP and one RP. |
| **TA-03** | Hierarchical Single-Root, Multi-Intermediate | A single Trust Anchor with two intermediate authorities; each intermediate manages its own OP and RP. |
| **TA-04** | Hierarchical Multi-Intermediate and Multi-Root | Two Trust Anchors: the first has two intermediates with an OP and RP each; the second has an OP and RP, but the OP also connects to one intermediate from the first Trust Anchor, forming a cross administrative federation link. |



### TA-01: Basic Topology

```
      [ Trust Anchor (Root) A ]
                  |
        ---------------------
        |                   |
     [ OP ]               [ RP ]
```

### TA-02: Hierarchical Single-Root Topology

```
          [ Trust Anchor (Root) A ]
                    |                   
            [ Intermediate A ]     
                    |                     
            -----------------           
            |               |           
        [ OP ]           [ RP ]        
```
### TA-03: Hierarchical Single-Root, Multi-Intermediate Topology (eduGAIN)

```
                [ Trust Anchor (Root) A ]
                         |
        -----------------------------------------
        |                                       |
  [ Intermediate A ]                    [ Intermediate B ]
        |                                       |
   ---------------                         ---------------
   |             |                         |             |
 [ OP ]        [ RP ]                   [ OP ]        [ RP ]
```

### TA-04: Hierarchical Multi-Root Topology

```
          [ Trust Anchor (Root) A ]                     
                  |            
        ------------------------- 
        |                       |  
[ Intermediate A ]      [ Intermediate B ]      [ Trust Anchor (Root) B ]
        |                       |                        |
   -------------           ------------------       ---------------- 
   |           |           |           |    |-------|             |
 [ OP ]      [ RP ]      [ OP ]      [ RP ]        [OP]          [RP]
 
```

### TA-05: Basic Topology with Trust Mark Issuer 

```
      [ Trust Anchor (Root) A ] -->[ Trust Mark Issuer A]
                  |
        ---------------------
        |                   |
     [ OP ]               [ RP ]
```


### TA-06: Hierarchical Single-Root, Multi-Intermediate Topology with Trust Mark Issuers (eduGAIN)

```
                     [ Trust Anchor (Root) A ] -->[ Trust Mark Issuer A]
                                  |
        -------------------------------------------------
        |                                               |
  [ Intermediate A ] -->[ Trust Mark Issuer B]   [ Intermediate B ]-->[ Trust Mark Issuer C]
        |                                               |
   ---------------                                 ---------------
   |             |                                 |             |
 [ OP ]        [ RP ]                            [ OP ]        [ RP ]
```

Noting: TA-01 represents national federation use cases, and TA-02 to TA-04 represent international federation use cases, such as eduGAIN. In addition, TA-05 and TA-06 introduce Trust Mark Issuers to validate trust mark scenarios.

In each test case, the architecture reference (e.g., TA-01) indicates which is the *minimum* topology to use to satisfy the given test—the same test can apply to other topologies.

## Federation Enrolment Test Cases


| Ref | Arch | Type | Test Name | Reason | Objective / Test Description | Validation / Expected Result |
|------|------|-----------|-----------|---------|-------------------------------|------------------------------|
| **FE-01** | TA-01 | Enrolment | Enrolment of an RP into a Trust Anchor | Trust Anchors MUST be capable of enrolling RPs | Verify that a Relying Party (RP) can be successfully enrolled into a federation Trust Anchor. | The enrolled entity is correctly listed at the `/list` endpoint and Entity Statements are issued about them from the `/fetch` endpoint. |
| **FE-02** | TA-01 | Enrolment | Enrolment of an OP into a Trust Anchor | Trust Anchors MUST be capable of enrolling OPs | Verify that an OpenID Provider (OP) can be successfully enrolled into a federation Trust Anchor. | The enrolled entity is correctly listed at the `/list` endpoint and Entity Statements are issued about them from the `/fetch` endpoint. |
| **FE-03** | TA-02 | Enrolment | Enrolment of a Trust Anchor into another Trust Anchor | National federations MUST be able to join international federations | Verify that a Trust Anchor can be successfully enrolled as an intermediate into another federation Trust Anchor. | The enrolled entity is correctly listed at the `/list` endpoint and Entity Statements are issued about them from the `/fetch` endpoint. |
| **FE-04** | TA-01 | Enrolment | Conditional Enrolment Based on Entity Identifier Policy | Trust Anchors / Intermediates SHOULD support policy based enrollment. | Test enrolment of an OP when subject to federation policies that only permits the OP by Entity Identifier. | The OP is correctly listed at the `/list` endpoint and an Entity Statement is issued about it from the `/fetch` endpoint. |
| **FE-05** | TA-01 | Enrolment | Conditional Enrolment Based on Entity Identifier Policy | Trust Anchors / Intermediates SHOULD support policy based enrollment. | Test enrolment of an OP when subject to federation policies that do *not* permit the OP by Entity Identifier. | The OP is not listed at the `/list` endpoint and an Entity Statement is *not* issued about them from the `/fetch` endpoint. |
| **FE-06** | TA-01 | Enrolment | Conditional Enrolment Based on Trust Marks | Trust Anchors / Intermediates SHOULD support policy based enrollment based on Trust Marks. | Test enrolment of an OP that has an eduGAIN Trust Mark when subject to federation policies that require an eduGAIN Trust Mark. | The OP is listed at the `/list` endpoint and an Entity Statement is issued about them from the `/fetch` endpoint. |
| **FE-07** | TA-01 | Enrolment | Conditional Enrolment Based on Trust Marks | Trust Anchors / Intermediates SHOULD support policy based enrollment based on Trust Marks. | Test enrolment of an OP that does **not** have an eduGAIN Trust Mark when subject to federation policies that require an eduGAIN Trust Mark. | The OP is not listed at the `/list` endpoint and an Entity Statement is *not* issued about them from the `/fetch` endpoint. |
| **FE-08** | TA-01 | Enrolment | Conditional Enrolment Based on Entity Identifier Policy | Trust Anchors / Intermediates SHOULD support policy based enrollment. | Test enrolment of an RP when subject to federation policies that only permits the RP by Entity Identifier. | The RP is correctly listed at the `/list` endpoint and an Entity Statement is issued about it from the `/fetch` endpoint. |
| **FE-09** | TA-01 | Enrolment | Conditional Enrolment Based on Entity Identifier Policy | Trust Anchors / Intermediates SHOULD support policy based enrollment. | Test enrolment of an RP when subject to federation policies that do *not* permit the RP by Entity Identifier. | The RP is not listed at the `/list` endpoint and an Entity Statements is *not* issued about it from the `/fetch` endpoint. |
| **FE-10** | TA-01 | Enrolment | Updating an Enrolled Entity | Trust Anchors / Intermediates MUST support updates to Entities | Allow an existing entity registration to be updated by its owner. | The entity registration is updated; only the owner can update; non-owners are rejected. |
| **FE-11** | TA-01 | Enrolment | Enrolment with Specific Display Name Attribute | Trust Anchors / Intermediates MUST be able to override self-asserted display attributes to provide trustworthy, consistent, values. | Verify that entities can be enrolled with TA-authorised attributes (like `display_name`) overriding self-asserted values. | Entity Statements published via `/fetch` contain the required attributes encoded in the `metadata` claim |
| **FE-12** | TA-01 | Unenrolment | Unenroll an RP from the Trust Anchor | Trust Anchors / Intermediates MUST support unenrolment of entities. | Ensure the RP can be removed from the federation Trust Anchor. | Unenrolled entities are not listed or trusted by the TA; they do not appear in `/list`, and `/fetch` will not issue Entity Statements about it. |
| **FE-13** | TA-01 | Unenrolment | Unenroll an OP from the Trust Anchor | Trust Anchors / Intermediates MUST support unenrolment of entities. | Ensure the OP can be removed from the federation Trust Anchor. | Unenrolled entities are not listed or trusted by the TA; they do not appear in `/list`, and `/fetch` will not issue Entity Statements about it. |
| **FE-14** | TA-02| Unenrolment | Unenroll a Trust Anchor from another Trust Anchor | National federations MUST be able to leave international federations | Ensure the intermediate Trust Anchor can be removed from the federation Trust Anchor. | Unenrolled entities are not listed or trusted by the TA; they do not appear in `/list`, and `/fetch` will not issue Entity Statements about it. |
| **FE-15** | TA-01 | Enrolment | Enrolment with Expired Signing Key | Trust Anchors / Intermediates MAY validate signing keys during enrolment. | Attempt to enrol an OP using an expired signing key as determined by the `federation_historical_keys` endpoint. | The enrolment is rejected with an appropriate error message indicating the signing key is expired. |


---

## Key Management Test Cases

| Ref | Arch | Type | Test Name | Reason | Objective / Test Description | Validation / Expected Result |
|------|-----|-----------|-----------|---------|-------------------------------|------------------------------|
| **KM-01** | TA-01| Key Rollover | Adding New Federation Signing Key | A federation operator MUST be able to add new signing keys without breaking trust. | Validate that new signing keys can be added to the TA’s JWK set, signed with the existing key, and leaf entities can replace their existing, trusted, TA key with the new key. | Entities recognize the new key as a trusted key. |
| **KM-02** | TA-01   | Key Rollover | Adding New Federation Signing Key | Leaf entities MUST correctly trust and validate documents signed with new keys. | Validate that the new signing keys established in KM-01 are trusted. | Entities recognize the new key as a trusted key, and correctly verify documents signed with the new key. |
| **KM-03** | TA-01 | Key Rollover | Removing Old Federation Signing Key | Leaf entities MUST only trust current, active signing keys. | Ensure old signing keys can be safely removed from the TA’s JWK set. | Only current keys are trusted; deprecated keys appear only in historical listings `federation_historical_keys`. |
| **KM-04** | TA-01  | Key Revocation | Revocation of TA Signing Key | Leaf entities MUST not used revoked TA signing keys.| Test the impact of revoking a TA’s signing key. | Documents signed with revoked keys are rejected; trust is not established. |
| **KM-05** | TA-01  | Key Revocation | Revocation of OP Federation Signing Key | RPs MUST not trust entity configurations signed by a revoked OP key | Ensure that revoking an OP’s federation signing key prevents trust establishment. | OP federation documents are no longer trusted. |
| **KM-06** | TA-01  | Key Revocation | Revocation of RP Federation Signing Key | OPs MUST not trust entity configurations signed by a revoked RP key | Ensure that revoking an RP’s federation signing key prevents trust establishment. | RP federation documents are no longer trusted. |

//TODO updating keys at the TA and ensuring entities pick up the changes
---

## Trust Mark Test Cases

| Ref | Arch | Category | Test Name | Reason | Objective / Test Description | Validation / Expected Result |
|------|------|-----------|-----------|---------|-------------------------------|------------------------------|
| **TM-01** | TA-05 | Trust Mark Issuance | Issuing Federation Membership Trust Marks | A Trust Mark Issuer SHOULD be capable of issuing valid trust marks to OPs, enabling policy-based trust. | Validate a federation membership trust mark, e.g., eduGAIN, can be correctly issued to an OP. | The trust mark is correctly formatted and signed. |
| **TM-02** | TA-05 | Trust Mark Issuance | Issuing Federation Membership Trust Marks |  A Trust Mark Issuer SHOULD be capable of issuing valid trust marks to RPs, enabling policy-based trust. | Validate a federation membership trust mark, e.g., eduGAIN, can be correctly issued to an RP. | The trust mark is correctly formatted and signed. |
| **TM-03** | TA-05 | Trust Mark Usage | OPs MUST enforce Federation Membership via Trust Marks | Verifies that OPs enforce trust mark requirements for RPs, ensuring policy compliance. | Ensure that trust marks are used by an RP to influence interoperability and trust decisions. | Ensure the OP requires an RP to contain the eduGAIN trust mark. |
| **TM-04** | TA-05 | Trust Mark Usage | RPs MUST enforce Federation Membership via Trust Marks | Confirms RPs enforce trust mark requirements for OPs, maintaining federation integrity. | Ensure that trust marks are used by an RP to influence interoperability and trust decisions. | Ensure the RP requires an OP to contain the eduGAIN trust mark. |
| **TM-05** | TA-05 | Trust Mark Revocation | Handling Invalid / Revoked / Expired Trust Marks | OPs MUST not trust revoked or expired trust marks on RPs, to maintain integrity. | Verify that a revoked or expired eduGAIN trust mark on the RP prevents trust establishment at the OP. | Trust is not established; trust mark status endpoint at the TA reflects the correct trust mark status (`/federation_trust_mark_status_endpoint`). |
| **TM-06** | TA-05 | Trust Mark Revocation | Handling Invalid / Revoked / Expired Trust Marks | RPs MUST not trust revoked or expired trust marks on OPs, to maintain trust | Verify that a revoked or expired eduGAIN trust mark on the OP prevents trust establishment at the RP. | Trust is not established; trust mark status endpoint at the TA reflects the correct trust mark status (`/federation_trust_mark_status_endpoint`). |
| **TM-07** | TA-06 | Trust Mark Delegation | Trust Mark Delegation | To validate delegation scenarios where trust marks are issued indirectly. | *TBD* | *TBD* |

---

## Federation Entity Discovery & Metadata Handling Test Cases

| Ref | Arch | Type | Test Name | Reason | Objective / Test Description | Validation / Expected Result |
|------|-----|-----------|-----------|---------|-------------------------------|------------------------------|
| **FD-01** | TA-02 | Trust Path Resolution | Handling embedded Trust Chains in RP’s Authentication Request | OPs MAY validate embedded trust chains to improve efficiency of trust resolution | Confirm that an OP can parse and validate embedded trust chains inside a Request Object. | OP successfully establishes trust if the embedded chain is valid. |
| **FD-02** | TA-02 | Trust Path Resolution | Expired Entity Statement in Embedded Trust Chain | OPs MUST reject expired statements in embedded chains, to maintain security | Ensure an OP rejects trust paths containing expired Entity Statements in the Trust Chain of a Request Object. | OP rejects the embedded Trust Chain but succeeds via Federation Entity Discovery. |
| **FD-03** | TA-02 | Trust Path Resolution | Expired Entity Statement in RP’s Trust Chain | OPs MUST reject expired statements during entity discovery to prevent stale trust paths. | Ensure OP rejects trust paths containing expired Entity Statements during Federation Entity Discovery. | OP fails to establish trust due to an expired Entity Statement. |
| **FD-04** | TA-04 | Trust Path Resolution | Multiple Trust Paths | OPs SHOULD select the shortest valid trust path for efficiency and correctness. | Validate that the OP selects the shortest, valid trust path among multiple available. | OP selects the shortest, common, valid trust path and successfully establishes trust with the RP. |
| **FD-05** | TA-02 | Metadata Constraints | Allowed Entity Types | OPs and RPs MUST enforce entity type constraints, preventing entities from changing their type on their own. | TA policy allows only `openid_relying_party` and `openid_provider` entities. | Trust chain resolution fails when entity changes to `federation_entity`. |
| **FD-06** | TA-02 | Metadata Constraints | Maximum Trust Path Length | OPs and RPs MUST enforce maximum trust path length constraints to reduce the risk of an RP or OP presenting other entities as an intermediate. | TA policy defines `max_path_length = 1`. A trust chain of 2 entities is presented. | Trust chain resolution fails as max path length is exceeded. |
| **FD-07** | TA-01 | Metadata Policy | Add Metadata Field | Trust Anchors SHOULD be capable of injecting policy-driven metadata into OP/RP configurations. | TA policy adds TA contact information into the OP/RPs metadata. | Resolved metadata contains the added contact information. |
| **FD-08** | TA-01 | Metadata Policy | Algorithm Constraints | Trust Anchors SHOULD be capable of enforcing cryptographic algorithm constraints for security compliance. | TA policy allows only `RS256` for `id_token` signing. OP/RP publishes unsupported signing algorithm, `ES256`, in its Entity Configuration metadata. | Trust chain validation fails; entity is not supported. |
| **FD-09** | TA-01 | Metadata Augmentation | Trust Anchor Asserted Values | Trust Anchors SHOULD be capable of overriding self-asserted metadata for consistency and trust. | Ensure TA-defined metadata overrides (e.g., `display_name`, `organization_name`) take precedence over self-asserted ones. | Clients use TA-defined values. |
| **FD-10** | TA-01 | Metadata Augmentation | Metadata Provided by the Trust Anchor | Trust Anchors SHOULD be capable of providing metadata that is correctly applied during trust resolution. | Verify that TA-provided metadata for an OP is correctly applied during trust resolution. | TA-provided metadata is visible in resolved configurations. |
| **FD-11** | TA-03 | Trust Path Resolution | Multiple Resolvers | OPs and RPs MAY support multiple trust resolvers for redundancy and reliability. | Validate that an OP can switch between different resolvers depending on availability | OP successfully establishes trust using any of available trust resovlers. |

//TODO multiple resolvers may provide different filtering / policies - how to test that?


---

## Client Registration Test Cases

| Ref | Arch | Category | Test Name | Reason | Objective / Test Description | Validation / Expected Result |
|------|-----|-----------|-----------|---------|-------------------------------|------------------------------|
| **CR-01** | TA-01 | Explicit Registration | Successful Registration | OPs MAY support explicit registration, allowing an easier migration path for RPs, and bi-lateral registration. | Validate that an RP using `client_secret_basic` client authentication can explicitly register with an OP. | RP receives valid credentials (`client_id`, `client_secret`) and can authenticate in subsequent OpenID Connect interactions. |
| **CR-02** | TA-01 | Explicit Registration | Unsuccessful Registration | OPs that support explicit registration MUST provide proper error handling for failed trust establishment. | Ensure proper error handling when trust cannot be established. | OP returns compliant error response when registration fails. |
| **CR-03** | TA-01 | Automatic Registration | Successful Registration | OPs MUST support automatic registration using signed Request Object JWTs, allowing large-scale multi-lateral federations. | Verify that an RP can automatically register with an OP using a signed Request Object JWT. | RP receives valid authentication response; trust established. |
| **CR-04** | TA-01 | Automatic Registration | Successful Registration | OPs MUST support automatic registration using signed and encrypted Request Object JWTs, allowing large-scale multi-lateral federations. | Verify that an RP can automatically register with an OP using a signed and encrypted Request Object JWT. | RP receives valid authentication response; trust established. |
| **CR-05** | TA-01 | Automatic Registration | Unsuccessful Registration | OPs MUST provide proper error handling for failed trust establishment. | Ensure automatic registration fails gracefully when trust cannot be established. | Confirm that the OP terminates the flow with an appropriate error response and does not perform a redirect to the `redirect_uri`. 
| **CR-06** | TA-02 | Automatic Registration | Registration with a hierachical trust chain | OPs MUST support automatic registration using signed Request Object JWTs with hierarchical trust chains, like eduGAIN. | Verify that an RP can automatically register with an OP using a signed Request Object JWT containing a hierarchical trust chain. | RP receives valid authentication response; trust established through the hierarchical chain. |
| **CR-07** | TA-02 | Explicit Registration | Registration with a hierachical trust chain | OPs MUST support explicit registration using signed Request Object JWTs with hierarchical trust chains, like eduGAIN. | Verify that an RP can automatically register with an OP using a signed Request Object JWT containing a hierarchical trust chain. | RP receives valid authentication response; trust established through the hierarchical chain. |

---

## Client Authentication Test Cases

| Ref | Arch | Type | Test Name | Reason | Objective / Test Description | Validation / Expected Result |
|------|-----|-----------|-----------|---------|-------------------------------|------------------------------|
| **CA-01** | TA-01 | Endpoint Authentication | `/resolve` Endpoint Authentication | Ensure that access to the resource-intensive and bandwidth-heavy resolution functionality is restricted to authorized clients. | Ensure that clients must authenticate to access the resolution functionality. | Only authenticated clients can retrieve resolved Entity Statements. |
| **CA-02** | TA-01 | Endpoint Authentication | `/fetch` Endpoint Authentication | Ensure that access to the resource-intensive fetch functionality is restricted to authorized clients. | Validate that client authentication is required to fetch Entity Statements. | Only authenticated clients can access signed Entity Statements. |
| **CA-03** | TA-01 | Endpoint Authentication | `/list` Endpoint Authentication | Prevent enumeration of entities to unauthorized clients. | Check that client authentication is required to list entities. | Only authenticated clients can retrieve entity lists. |


---



