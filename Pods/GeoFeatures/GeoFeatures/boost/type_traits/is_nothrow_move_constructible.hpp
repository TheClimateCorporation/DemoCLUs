
//  (C) Copyright Steve Cleary, Beman Dawes, Howard Hinnant & John Maddock 2000.
//  (C) Copyright Eric Friedman 2002-2003.
//  (C) Copyright Antony Polukhin 2013.
//  Use, modification and distribution are subject to the Boost Software License,
//  Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt).
//
//  See http://www.boost.org/libs/type_traits for most recent version including documentation.

#ifndef BOOST_TT_IS_NOTHROW_MOVE_CONSTRUCTIBLE_HPP_INCLUDED
#define BOOST_TT_IS_NOTHROW_MOVE_CONSTRUCTIBLE_HPP_INCLUDED

#include <boost/config.hpp>
#include <boost/type_traits/intrinsics.hpp>
#include <boost/type_traits/has_trivial_move_constructor.hpp>
#include <boost/type_traits/has_nothrow_copy.hpp>
#include <boost/type_traits/is_array.hpp>
#include <boost/type_traits/is_reference.hpp>
#include <boost/type_traits/detail/ice_or.hpp>
#include <boost/type_traits/detail/ice_and.hpp>
#include <boost/utility/declval.hpp>
#include <boost/utility/enable_if.hpp>

// should be the last #include
#include <boost/type_traits/detail/bool_trait_def.hpp>

namespace geofeatures_boost {} namespace boost = geofeatures_boost; namespace geofeatures_boost {

namespace detail{

#ifdef BOOST_IS_NOTHROW_MOVE_CONSTRUCT

template <class T>
struct is_nothrow_move_constructible_imp{
   BOOST_STATIC_CONSTANT(bool, value = BOOST_IS_NOTHROW_MOVE_CONSTRUCT(T));
};

template <class T>
struct is_nothrow_move_constructible_imp<volatile T> : public ::geofeatures_boost::false_type {};
template <class T>
struct is_nothrow_move_constructible_imp<const volatile T> : public ::geofeatures_boost::false_type{};
template <class T>
struct is_nothrow_move_constructible_imp<T&> : public ::geofeatures_boost::false_type{};
#ifndef BOOST_NO_CXX11_RVALUE_REFERENCES
template <class T>
struct is_nothrow_move_constructible_imp<T&&> : public ::geofeatures_boost::false_type{};
#endif

#elif !defined(BOOST_NO_CXX11_NOEXCEPT) && !defined(BOOST_NO_SFINAE_EXPR)

template <class T, class Enable = void>
struct false_or_cpp11_noexcept_move_constructible: public ::geofeatures_boost::false_type {};

template <class T>
struct false_or_cpp11_noexcept_move_constructible <
        T,
        typename ::geofeatures_boost::enable_if_c<sizeof(T) && BOOST_NOEXCEPT_EXPR(T(::geofeatures_boost::declval<T>()))>::type
    > : public ::geofeatures_boost::integral_constant<bool, BOOST_NOEXCEPT_EXPR(T(::geofeatures_boost::declval<T>()))>
{};

template <class T>
struct is_nothrow_move_constructible_imp{
   BOOST_STATIC_CONSTANT(bool, value = ::geofeatures_boost::detail::false_or_cpp11_noexcept_move_constructible<T>::value);
};

template <class T>
struct is_nothrow_move_constructible_imp<volatile T> : public ::geofeatures_boost::false_type {};
template <class T>
struct is_nothrow_move_constructible_imp<const volatile T> : public ::geofeatures_boost::false_type{};
template <class T>
struct is_nothrow_move_constructible_imp<T&> : public ::geofeatures_boost::false_type{};
#ifndef BOOST_NO_CXX11_RVALUE_REFERENCES
template <class T>
struct is_nothrow_move_constructible_imp<T&&> : public ::geofeatures_boost::false_type{};
#endif

#else

template <class T>
struct is_nothrow_move_constructible_imp{
    BOOST_STATIC_CONSTANT(bool, value =(
        ::geofeatures_boost::type_traits::ice_and<
            ::geofeatures_boost::type_traits::ice_or<
                ::geofeatures_boost::has_trivial_move_constructor<T>::value,
                ::geofeatures_boost::has_nothrow_copy<T>::value
            >::value,
            ::geofeatures_boost::type_traits::ice_not< ::geofeatures_boost::is_array<T>::value >::value
        >::value));
};

#endif

}

BOOST_TT_AUX_BOOL_TRAIT_DEF1(is_nothrow_move_constructible,T,::geofeatures_boost::detail::is_nothrow_move_constructible_imp<T>::value)

BOOST_TT_AUX_BOOL_TRAIT_SPEC1(is_nothrow_move_constructible,void,false)
#ifndef BOOST_NO_CV_VOID_SPECIALIZATIONS
BOOST_TT_AUX_BOOL_TRAIT_SPEC1(is_nothrow_move_constructible,void const,false)
BOOST_TT_AUX_BOOL_TRAIT_SPEC1(is_nothrow_move_constructible,void const volatile,false)
BOOST_TT_AUX_BOOL_TRAIT_SPEC1(is_nothrow_move_constructible,void volatile,false)
#endif

} // namespace geofeatures_boost

#include <boost/type_traits/detail/bool_trait_undef.hpp>

#endif // BOOST_TT_IS_NOTHROW_MOVE_CONSTRUCTIBLE_HPP_INCLUDED
