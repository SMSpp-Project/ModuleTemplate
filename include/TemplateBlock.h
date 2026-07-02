/*--------------------------------------------------------------------------*/
/*-------------------------- File TemplateBlock.h --------------------------*/
/*--------------------------------------------------------------------------*/
/** @file
 * Header file for the *concrete* class TemplateBlock, which implements the
 * Block concept [see Block.h]. This is a minimal, compilable skeleton meant
 * to be replaced with the actual model: it shows the canonical structure of
 * an SMS++ Block (factory registration, deserialize() from netCDF, the
 * generation of the "abstract representation") with the standard file
 * layout and comment style of the SMS++ project.
 *
 * \author Template Author \n
 *         Dipartimento di Informatica \n
 *         Universita' di Pisa \n
 *
 * \copyright &copy; by Template Author
 */
/*--------------------------------------------------------------------------*/
/*----------------------------- DEFINITIONS --------------------------------*/
/*--------------------------------------------------------------------------*/

#ifndef __TemplateBlock
 #define __TemplateBlock
                      /* self-identification: #endif at the end of the file */

/*--------------------------------------------------------------------------*/
/*------------------------------ INCLUDES ----------------------------------*/
/*--------------------------------------------------------------------------*/

#include "Block.h"

/*--------------------------------------------------------------------------*/
/*------------------------------ NAMESPACE ---------------------------------*/
/*--------------------------------------------------------------------------*/

/// namespace for the Structured Modeling System++ (SMS++)
namespace SMSpp_di_unipi_it
{
/*--------------------------------------------------------------------------*/
/*-------------------------------- CLASSES ---------------------------------*/
/*--------------------------------------------------------------------------*/
/** @defgroup TemplateBlock_CLASSES Classes in TemplateBlock.h
 *  @{ */

/*--------------------------------------------------------------------------*/
/*--------------------------- CLASS TemplateBlock ---------------------------*/
/*--------------------------------------------------------------------------*/
/// implementation of the Block concept for ... (describe the model here)
/** The TemplateBlock class implements the Block concept [see Block.h] for
 * ... (describe here the mathematical structure the Block encodes: the
 * Variable it holds, the Constraint linking them, the Objective).
 *
 * This skeleton only provides the mandatory machinery: replace the TODOs
 * with the actual model. */

class TemplateBlock : public Block
{
/*----------------------- PUBLIC PART OF THE CLASS -------------------------*/

 public:

/*------------------------------ CONSTRUCTOR --------------------------------*/
 /// constructor of TemplateBlock, taking a pointer to the father Block
 /** Constructor of TemplateBlock. It accepts a pointer to the father Block
  * (defaulting to nullptr, both because the root Block has no father and so
  * that this can also be used as the void constructor required by the Block
  * factory). */

 explicit TemplateBlock( Block * father = nullptr )
  : Block( father ) , AR( 0 ) {}

/*------------------------------ DESTRUCTOR ---------------------------------*/
 /// destructor of TemplateBlock

 virtual ~TemplateBlock() = default;

/*-------------------------- OTHER INITIALIZATIONS --------------------------*/
 /// extends Block::deserialize( netCDF::NcGroup )
 /** Extends Block::deserialize( netCDF::NcGroup ) to the specific format of
  * TemplateBlock. Besides the mandatory "type" attribute of any :Block, the
  * group should contain the data describing the model.
  *
  * TODO: read the model data from \p group, then call the base class
  * method. */

 void deserialize( const netCDF::NcGroup & group ) override
 {
  // TODO: read the TemplateBlock-specific data out of group

  Block::deserialize( group );
  }

/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
 /// loads the TemplateBlock out of an istream
 /** Loads the TemplateBlock out of an istream, whose format is defined by
  * \p frmt.
  *
  * TODO: implement (or leave the throw if only netCDF input is
  * supported). */

 void load( std::istream & input , char frmt = 0 ) override
 {
  throw( std::logic_error( "TemplateBlock::load: not implemented yet" ) );
  }

/*---------------------- Methods for handling Variable ----------------------*/
 /// generates the abstract Variable of the TemplateBlock
 /** TODO: construct the ColVariable (or :Variable) of the model and expose
  * them with add_static_variable() / add_dynamic_variable(). */

 void generate_abstract_variables( Configuration * stvv = nullptr ) override
 {
  if( AR & HasVar )  // the Variable are there already
   return;           // nothing to do

  // TODO: generate the Variable here and expose them
  //       with add_static_variable() / add_dynamic_variable()

  AR |= HasVar;
  }

/*--------------------- Methods for handling Constraint ---------------------*/
 /// generates the abstract Constraint of the TemplateBlock
 /** TODO: construct the Constraint of the model and expose them with
  * add_static_constraint() / add_dynamic_constraint(). */

 void generate_abstract_constraints( Configuration * stcc = nullptr ) override
 {
  if( AR & HasCns )  // the Constraint are there already
   return;           // nothing to do

  // TODO: generate the Constraint here and expose them
  //       with add_static_constraint() / add_dynamic_constraint()

  AR |= HasCns;
  }

/*---------------------- Methods for handling Objective ---------------------*/
 /// generates the abstract Objective of the TemplateBlock
 /** TODO: construct the Objective and set it with set_objective(). */

 void generate_objective( Configuration * objc = nullptr ) override
 {
  if( AR & HasObj )  // the Objective is there already
   return;           // nothing to do

  // TODO: generate the Objective here and set it with set_objective()

  AR |= HasObj;
  }

/*------------- Methods for checking the state of the TemplateBlock ---------*/
 /// returns true if any part of the abstract representation is there

 bool anyone_there( void ) const override
 {
  return( AR ? true : Block::anyone_there() );
  }

/*-------------------- PROTECTED PART OF THE CLASS --------------------------*/

 protected:

/*--------------------------- PROTECTED METHODS ------------------------------*/
 /// prints the TemplateBlock on an ostream with the given verbosity
 /** TODO: implement the "complete" formats (matching load()) if needed. */

 void print( std::ostream & output , char vlvl = 0 ) const override
 {
  output << "TemplateBlock" << std::endl;
  }

/*--------------------------- PROTECTED FIELDS ------------------------------*/

 // TODO: the data of the model goes here

 unsigned char AR;     ///< bit-wise coded: what abstract is there

 static constexpr unsigned char HasVar = 1;
 ///< first bit of AR == 1 if the Variable have been constructed
 static constexpr unsigned char HasObj = 2;
 ///< second bit of AR == 1 if the Objective has been constructed
 static constexpr unsigned char HasCns = 4;
 ///< third bit of AR == 1 if the Constraint have been constructed

/*--------------------- PRIVATE PART OF THE CLASS ---------------------------*/

 private:

/*-------------------------- PRIVATE METHODS --------------------------------*/

 SMSpp_insert_in_factory_h;  // insert TemplateBlock in the Block factory

/*--------------------------------------------------------------------------*/

 };  // end( class( TemplateBlock ) )

/** @} end( group( TemplateBlock_CLASSES ) ) */

/*--------------------------------------------------------------------------*/

 }  // end( namespace SMSpp_di_unipi_it )

/*--------------------------------------------------------------------------*/

#endif  /* TemplateBlock.h included */

/*--------------------------------------------------------------------------*/
/*------------------------ End File TemplateBlock.h ------------------------*/
/*--------------------------------------------------------------------------*/
