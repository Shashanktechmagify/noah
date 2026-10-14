/// The ministry's Terms & Conditions, as supplied by Karuna Sadan Ministries.
/// Legal wording: shown as is (English). Translations must come from the
/// ministry, and the server should version this text.
class LegalBlock {
  const LegalBlock({
    this.heading,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  /// Small sub-heading (e.g. "COOKIES"); null for untitled text.
  final String? heading;
  final List<String> paragraphs;
  final List<String> bullets;
}

class LegalPart {
  const LegalPart(this.id, this.title, this.blocks);

  final String id;
  final String title;
  final List<LegalBlock> blocks;
}

const kTermsVersion = '1.0';

const kLegalParts = [
  LegalPart('about', 'About', [
    LegalBlock(
      paragraphs: [
        'NOAH is an App by Karuna Sadan Ministries (KSM). The NOAH App is an MRM (Member Relationship Management) solution for Churches and Ministries that helps streamline and digitalize member databases and outreach processes.',
        '‘Karuna Sadan, ’ meaning House of Compassion, was founded in the year 2006 by Pastor Michael Fernandes and his wife, Pastor Anita Fernandes. It was registered under Section 12AA of the Income Tax Act, India',
        'Karuna Sadan meets the diverse needs of the community through ministries such as:',
      ],
      bullets: [
        'Counseling of terminally ill persons and physically disabled persons',
        'Counseling for people affected with AIDS/HIV or AIDS',
        'Counseling for those given to excess alcohol',
        'Physically or mentally abused persons (such as rape, depression, trauma etc)',
        'Feeding the poor and marginalized',
        'Free music education for children who are interested',
        'Taking care of widows who are abandoned',
        'Career counseling for students who have failed or performed poorly in academics',
      ],
    ),
    LegalBlock(
      paragraphs: [
        'Your support of this ministry allows us to be the hands and feet of hope to those in need. Learn more at www.karunasadan.com',
      ],
    ),
  ]),
  LegalPart('privacy', 'Privacy Policy', [
    LegalBlock(
      paragraphs: [
        'Karuna Sadan Ministries ("KSM") is a nonprofit organization committed to excellence, integrity, and your privacy. This Policy is provided to inform you of the ways KSM uses information on the NOAH Website or App(s) www.noah.church ("Website/App(s)"). This Policy does not apply to any Website/App(s) "linked" to this Website/App(s), and KSM is not responsible for the privacy policies or the content of other Website/App(s).',
      ],
    ),
    LegalBlock(
      heading: 'INFORMATION COLLECTION',
      paragraphs: [
        'Please be aware that KSM is committed to upholding the highest level of confidentiality and security for those who choose to visit our Website/App(s). The types of information collected by KSM on this Website/App(s) fall under one of two categories: Anonymous or Personal.',
      ],
    ),
    LegalBlock(
      heading: 'ANONYMOUS INFORMATION',
      paragraphs: [
        'Anonymous information cannot be traced back to a specific individual. Web servers automatically record the IP address (the general location where the user is logged) of each visitor to this Website/App(s) and tracks how many people visit the Website/App(s). This anonymous information is used to administer and specialize the Website/App(s) more effectively and gain general information about the backgrounds and sources of visitors.',
      ],
    ),
    LegalBlock(
      heading: 'PERSONAL INFORMATION',
      paragraphs: [
        'Personal information identifies specific individuals. This information is personally and voluntarily provided as a result of a prompt on the Website/App(s). Such information includes, but is not limited to, names, postal addresses, phone numbers, email addresses and other demographic information. The data provided to the America section of the Website/App(s) (e.g. date of birth, marital status, gender, demographics, etc.) is handled by a third party.',
        'KSM collects personal information from this Website/App(s) thru:',
      ],
    ),
    LegalBlock(
      heading: 'ONLINE REQUESTS FOR INFORMATION',
      paragraphs: [
        'When requests are made on the Website/App(s), certain information is needed to process the request. The information may include, but is not limited to, names, postal addresses, phone numbers, email addresses, and other demographic information. The data provided to the America section of the Website/App(s) (e.g. date of birth, marital status, gender, demographics, etc.) is handled by a third party Unless you "opt out," we may also use that information to send you additional literature about KSM and its conferences and resources.',
      ],
    ),
    LegalBlock(
      heading: 'ONLINE REGISTRATION OF OUR PARTNERS',
      paragraphs: [
        'When an individual becomes a partner with KSM, certain information is collected to allow us to provide you with the highest degree of excellent service. The information collected in our online registration may include, but is not limited to, names, postal addresses, phone numbers, email addresses, and other demographic information. In the case of information provided to the America section of the Website/App(s) (such as date of birth, marital status, gender, demographics, and other information), this data is handled by a third party. Please be aware that we value your privacy, and your registration information is protected by password for your privacy and security. Unless you "opt out," this information may be used to send you additional literature about KSM conferences and resources.',
      ],
    ),
    LegalBlock(
      heading: 'ONLINE TRANSACTIONS',
      paragraphs: [
        'Purchases and donations made online from KSM require certain information to ensure the transaction is processed efficiently, correctly and safely. Information collected may include, but is not limited to, names, credit card information, mailing addresses, phone numbers, date of birth, marital status as well as other demographic information. All of the information you supply to KSM is never shared with others and is protected by encryption from the time it leaves your computer until the transactions is complete.',
      ],
    ),
    LegalBlock(
      heading: 'COOKIES',
      paragraphs: [
        'Cookies are small data files that can be placed on hard drives by Website/App(s) visited. The only personal information that a cookie can contain is the information that is provided. KSM uses cookies to gather and store personal information that is collected when online transactions occur through the Website/App(s), as well as passwords (used for secure login) and preferences of partners visiting the Website/App(s).',
      ],
    ),
    LegalBlock(
      heading: 'INFORMATION SHARING AND DISCLOSURE',
      paragraphs: [
        'KSM will not rent, sell, lease, or share personal information with other organizations, except in response to subpoenas, court orders, legal processes, or to establish and/or exercise legal rights. However, when an online transaction occurs that involves the shipment of a package, email addresses are provided to the shipping provider for tracking purposes only.',
      ],
    ),
    LegalBlock(
      heading: 'MINOR POLICY',
      paragraphs: [
        'Users under the age of sixteen must ask parent or guardian permission to email this Website/App(s), request information from KSM, or purchase any resources on this Website/App(s).',
      ],
    ),
  ]),
  LegalPart('terms', 'Terms of Service', [
    LegalBlock(
      paragraphs: [
        'The use of the Karuna Sadan Ministries Website/App(s) is subject to the terms of use as defined and governed by this copyright policy, which constitutes a legal binding agreement between you and Karuna Sadan Ministries. By using this Website/App(s) you hereby acknowledge that you have read, understood, and are in agreement to be bound by the terms of use as defined and governed by this copyright policy.',
      ],
    ),
    LegalBlock(
      heading: 'Restrictions',
      paragraphs: [
        'All information and or content provided by Karuna Sadan Ministries\' Website/App(s) is protected by copyright laws and is owned by Karuna Sadan Ministries. This information and or content includes, but is not limited to, graphics, images, photographs, audio clips, video clips, text, articles, and the Karuna Sadan Ministries logo, which is a trademark of Karuna Sadan Ministries.',
        'You may not publish, modify, copy, distribute, sell, transfer, or reproduce in any way the material on this Website/App(s) without prior written permission from Karuna Sadan Ministries. You may not, without the permission of Karuna Sadan Ministries, mirror or frame any material which is contained on this Website/App(s).',
        'Karuna Sadan Ministries also prohibits unauthorized links to the site and reserves the right to disable any unauthorized links or frames.',
        'This site may contain links that will let you access other Website/App(s) that are not under the control of Karuna Sadan Ministries. The links are only provided as a convenience, and Karuna Sadan Ministries does not endorse any of these sites. Karuna Sadan Ministries assumes no responsibility or liability for any material that may be accessed on other Website/App(s) reached through this site, nor does Karuna Sadan Ministries make any representation regarding the quality of any product or service contained at any such site. Karuna Sadan Ministries has no responsibility or liability for any material on other Website/App(s) that may contain links to this site.',
        'The unauthorized use of any of the material contained on this Website/App(s) may violate certain copyright laws, trademark laws, communications regulations and statutes, and laws concerning privacy and publicity.',
      ],
    ),
  ]),
  LegalPart('refund', 'Refund Policy', [
    LegalBlock(
      paragraphs: [
        'Karuna Sadan Ministries (KSM) has a no-refunds and no-returns policy. All Purchases and Donations made are final and will not be refunded unless deemed otherwise at the sole discretion of the KSM management.',
      ],
    ),
  ]),
];
