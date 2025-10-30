import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



class UserBooking extends StatelessWidget {
  const UserBooking({super.key});

  @override
  Widget build(BuildContext context) {
    const brand = _Brand();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: brand.primary),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home:  UserBookingHome(),
    );
  }
}

class _Brand {
  const _Brand();

  final primary = const Color(0xFF5C2E91); // deep purple
  final primaryDark = const Color(0xFF3E1E69);
  final fieldBg = const Color(0xFFF5F3F9);
  final page = const Color(0xFFF8F7FB);
  final outline = const Color(0xFFDCD4EB);
  final textMuted = const Color(0xFF6C6A7A);
}

class UserBookingHome extends StatelessWidget {
  const UserBookingHome({super.key});

  @override
  Widget build(BuildContext context) {
    const brand = _Brand();
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: brand.page,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting + location
              Text(
                'Good Morning',
                style: TextStyle(
                  color: brand.primary,
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 18, color: brand.primary),
                  const SizedBox(width: 6),
                  Text(
                    'New York, NY',
                    style: TextStyle(
                       fontFamily: 'Poppins',
                      color: brand.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Search
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brand.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for services....',
                    hintStyle: TextStyle(color: brand.textMuted, fontFamily: 'Poppins',fontWeight: FontWeight.w500,fontSize: 14),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.search_rounded, color: brand.primary),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Promo card
              _PromoCard(
                width: w *0.99,
                onTap: () {},
              ),

              const SizedBox(height: 16),

              // Image banner
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    // placeholder stock image
                    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=1600&auto=format&fit=crop',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Quick Actions',
                style: TextStyle(
                   fontFamily: 'Poppins',
                  color: brand.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Book Service',
                      subtitle: 'Book\nprofessional services',
                      icon: Icons.event_available_rounded,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Emergency',
                      subtitle: '24/7 urgent\nservices',
                      icon: Icons.emergency_share_rounded,
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'Recent Activity',
                style: TextStyle(
                   fontFamily: 'Poppins',
                  color: brand.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 28),

              // Empty state
              Center(
                child: Column(
                  children: [
                    Text(
                      'No Recent bookings',
                      style: TextStyle(
                         fontFamily: 'Poppins',
                        color: Colors.black.withOpacity(.8),
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Book your first service to see activity here',
                      style: TextStyle(
                         fontFamily: 'Poppins',
                        color: brand.textMuted,
                        fontSize: 13.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.width, required this.onTap});
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const brand = _Brand();

    return Container(
      width: MediaQuery.of(context).size.width *90,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brand.primary, brand.primary.withOpacity(.92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: brand.primary.withOpacity(.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need professional services?',
            style: const TextStyle(
               fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 18.5,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with trusted service providers in\nyour area',
            style: TextStyle(
               fontFamily: 'Poppins',
              color: Colors.white.withOpacity(.9),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: brand.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child:  Text(
                
                'BROWSE CATEGORIES',
                style: TextStyle( fontFamily: 'Poppins',fontWeight: FontWeight.w600, letterSpacing: .2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const brand = _Brand();

    return Container(
      height: 97,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: brand.primary, width: 1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: brand.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: brand.primary),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                           fontFamily: 'Poppins',
                          color: brand.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                         fontFamily: 'Poppins',
                        color: brand.textMuted,
                        height: 1.05,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
