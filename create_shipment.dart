import 'package:flutter/material.dart';
import 'package:freightcab_shipper/constants/enums/appointment_type.dart';
import 'package:freightcab_shipper/constants/enums/item_unit.dart';
import 'package:freightcab_shipper/constants/enums/piece_type.dart';
import 'package:freightcab_shipper/constants/enums/accessory.dart';
import 'package:freightcab_shipper/constants/enums/stop_type.dart';
import 'package:freightcab_shipper/constants/enums/temperature_unit.dart';
import 'package:freightcab_shipper/models/accessories.dart';
import 'package:freightcab_shipper/models/shipment.dart';
import 'package:freightcab_shipper/models/stop.dart';
import 'package:freightcab_shipper/models/stopPoint.dart';
import 'package:freightcab_shipper/ui/shared/extensions.dart';
import 'package:freightcab_shipper/ui/views/section1.dart';
import 'package:freightcab_shipper/ui/views/section2.dart';
import 'package:freightcab_shipper/ui/views/view_shipment.dart';
import 'package:freightcab_shipper/ui/widgets/indicators.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../models/graphql/q.graphql_api.graphql.dart';

import 'footer.dart';
import 'section3.dart';

class CreateShipmentScreen extends StatefulWidget {
  final bool isEdit;
  final Shipment shipment;
  const CreateShipmentScreen({Key key, this.isEdit = false, this.shipment})
      : super(key: key);

  @override
  _CreateShipmentScreenState createState() => _CreateShipmentScreenState();

  static _CreateShipmentScreenState of(BuildContext context) =>
      context.findAncestorStateOfType<_CreateShipmentScreenState>();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final formKey = GlobalKey<FormState>();

  String uuid;
  int id;
  // booleans
  bool _isMultipleStops = false;
  bool _isReefer = false;
  bool _estimate = true;
  bool get isMultipleStops => _isMultipleStops;
  bool get isReefer => _isReefer;
  bool get estimate => _estimate;

  // textfield saved
  String maxSaved = '';
  String minSaved = '';
  String descSaved = '';
  String shortSaved = '';
  String weightSaved = '';
  String quantitySaved = '';
  String packingSaved = '';
  String loadDescSaved = '';

  TemperatureUnit selectedTempType = TemperatureUnit.C;
  ItemUnit selectedQuantityType = ItemUnit.UNITS;
  PieceType selectedPackageType = PieceType.PALLETS;

  // stop points
  List<Stop> stops = [
    Stop(),
    Stop(),
  ];
  List<StopPoint> stopPoints = [
    StopPoint(
      label: 'Pick up location',
      stopType: StopType.PICKUP,
    ),
    StopPoint(
      label: 'Drop off location',
      stopType: StopType.DROPOFF,
    ),
  ];

  // distance info
  double distanceMile = 0.0;
  int transitionTime = 0;
  bool isLoading = false;
  bool isFirst = true;
  Shipment shipment;
  bool isEdit;

  // accessories
  List<Accessories> accessoriesList = [];

  @override
  void initState() {
    super.initState();
    shipment = widget.shipment;
    isEdit = widget.isEdit;
    if (widget.isEdit) {
      stops = widget.shipment.stops;
      print(stops.first.appointmentType.name);
      stopPoints = stops
          .map((e) => StopPoint(
              startTime: e.startTime,
              label: 'old',
              endTime: e.endTime,
              stopType: e.type,
              appointmentType: e.appointmentType))
          .toList();
      selectedTempType = shipment.trailer.temperatureUnit ?? TemperatureUnit.C;
      selectedQuantityType = shipment.items.first.unit.type ?? ItemUnit.UNITS;
      selectedPackageType =
          shipment.items.first.handlingPiece.pieceType ?? PieceType.PALLETS;
      uuid = widget.shipment.uuid;
      id = widget.shipment.id;
      _isMultipleStops = stops.length == 2 ? false : true;
      _isReefer = widget.shipment.trailer.temperatureMin != null;
      maxSaved = widget.shipment.trailer.temperatureMax?.toString();
      minSaved = widget.shipment.trailer.temperatureMin?.toString();
      shortSaved = widget.shipment.shortName;
      descSaved = widget.shipment.items.first.description;
      loadDescSaved = widget.shipment.loadDescription;
      weightSaved = widget.shipment.items.first.weight.weight.toString();
      quantitySaved = widget.shipment.items.first.unit.count.toString();
      packingSaved =
          widget.shipment.items[0].handlingPiece.pieceCount.toString();
      accessoriesList = List.from(Accessory.values.map((element) => Accessories(
          type: element,
          label: element.text,
          isChecked: widget.shipment.accessories.contains(element))));
    } else {
      accessoriesList = List.from(Accessory.values.map((element) => Accessories(
            type: element,
            label: element.text,
          )));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  set isMultipleStops(bool value) {
    setState(() {
      _isMultipleStops = value;
    });
  }

  set isReefer(bool value) {
    setState(() {
      _isReefer = value;
    });
  }

  set estimate(bool value) {
    setState(() {
      _estimate = value;
    });
  }

  reload() {
    setState(() {});
  }

  void onAddStopPointTap() {
    estimate = false;
    setState(() {
      stopPoints.insert(
          stopPoints.length - (stopPoints.length == 2 ? 1 : 2), StopPoint());
      stops.insert(stops.length - (stops.length == 2 ? 1 : 2), Stop());
    });
  }

  /// remove stop point from existing stop point
  /// list (available only for multiple stops)
  void onRemoveStopPointTap(int index) {
    setState(() {
      stopPoints.removeAt(index);
      stops.removeAt(index);
    });
  }

  /// insert stop point to existing stop point
  /// list (available only for multiple stops)
  void onInsertStopPointTap(int newIndex, StopPoint item, Stop stop) {
    setState(() {
      stopPoints.insert(newIndex, item);
      stops.insert(newIndex, stop);
    });
  }

  setDurationAndTime(double mile, int time) {
    distanceMile = mile;
    transitionTime = time;
    // notifyListeners();
  }

  saveFacilityEditing(
    dynamic location,
    String opName,
    String opPhone,
    String opEmail,
    String schName,
    String schPhone,
    String schEmail,
  ) {
    var indexOf = stopPoints.indexWhere(
      (e) => e.location.id == location.id,
    );
    stopPoints[indexOf].location.operationalContact.contactName = opName;
    stopPoints[indexOf].location.operationalContact.phoneNumber = opPhone;
    stopPoints[indexOf].location.operationalContact.email = opEmail;
    stopPoints[indexOf].location.schedulingContact.contactName = schName;
    stopPoints[indexOf].location.schedulingContact.phoneNumber = schPhone;
    stopPoints[indexOf].location.schedulingContact.email = schEmail;
  }

  Widget getEstimation(bool isMile) {
    // if (isEdit) {
    //   if (isMile)
    //     return Text(shipment.routeDistanceMiles.toStringAsFixed(2) + ' miles');
    //   return Text(convertMintoDay(shipment.routeDurationMinutes.toString()));
    // }
    final locations = stopPoints.map((e) {
      if (e.location != null) return e.location;
    }).toList();
    return locations.isEmpty || !locations.contains(null)
        ? Query(
            options: WatchQueryOptions(
              document: GetEstimationQuery().document,
              variables: {
                "locations": List.generate(locations.length, (index) {
                  return LocationCollectionInput(
                    coordinates: CoordinatesInput(
                      lat: locations[index].coordinates.lat,
                      lng: locations[index].coordinates.lng,
                    ),
                  );
                }),
              },
            ),
            builder: (result, {refetch, fetchMore}) {
              if (result.hasException) {
                return GestureDetector(
                  onTap: () => refetch(),
                  child: Center(child: Text('')),
                );
              }

              if (result.isLoading && result.data == null) return Text('');

              final resultData = GetEstimation$Query.fromJson(result.data);
              setDurationAndTime(
                resultData.getEstimations.routeDistanceMiles,
                resultData.getEstimations.routeDurationMinutes,
              );

              var distance = resultData.getEstimations.routeDistanceMiles
                  .toStringAsFixed(2);
              print(distance);
              var duration = convertMintoDay(
                resultData.getEstimations.routeDurationMinutes.toString(),
              );
              return isMile ? Text("$distance miles") : Text(duration);
            },
          )
        : Text('');
  }

  onCreated(id, uuid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewShipmentPage(
          uuid,
          fromCreate: true,
        ),
      ),
    );
  }

  void onReviewTap(RunMutation runMutation) {
    List<String> selectedAccessories = accessoriesList
        .where((e) => e.isChecked == true)
        .map((e) => e.type.describe)
        .toList();

    hideKeyboard();
    if (isLoading) {
      return;
    }

    for (var stop in stopPoints) {
      if (stop.location == null) {
        showSnackbar(context, 'Please provide stop point', false);
        return;
      } else if (stop.startTime == null) {
        showSnackbar(context, 'Please provide start time', false);
        return;
      } else if (stop.appointmentType == null) {
        showSnackbar(context, 'Please provide appointment type', false);
        return;
      } else if (stop.appointmentType == AppointmentType.TO_BE_MADE &&
          stop.endTime == null) {
        showSnackbar(context, 'Please provide end time', false);
        return;
      }
    }

    if (formKey.currentState.validate()) {
      formKey.currentState.save();

      if (uuid == null) {
        runMutation({
          "input": {
            "open_price": 0,
            "shipment": {
              "short_name": shortSaved,
              "requested_truck_types": [isReefer ? "REEFER" : "DRY_VAN"],
              "accessorials": selectedAccessories,
              "load_description": loadDescSaved,
              "route_distance_miles": distanceMile,
              "route_duration_minutes": transitionTime,
              "stops": stopPoints.map((stop) {
                print(formatISOTime(stop.startTime));
                return {
                  "location_profile_id": stop.location.id,
                  "appointment_type": stop.appointmentType.describe,
                  "start_time": formatISOTime(stop.startTime),
                  "end_time": stop.appointmentType == AppointmentType.TO_BE_MADE
                      ? formatISOTime(stop.endTime)
                      : null,
                  "type": stop.stopType.describe,
                  "loading_type": "LIVE",
                  "location_input": {
                    "location_name": stop.location.locationName,
                    "coordinates": stop.location.coordinates.toJson(),
                    "address": stop.location.address.toJson(),
                    "operational_contact":
                        stop.location.operationalContact.toJson(),
                    "scheduling_contact":
                        stop.location.schedulingContact.toJson(),
                  }
                };
              }).toList(),
              "items": [
                {
                  "description": descSaved,
                  "handling_piece": {
                    "piece_type": selectedPackageType.describe,
                    "piece_count": intParse(packingSaved),
                  },
                  "units": {
                    "unit_count": intParse(quantitySaved),
                    "unit_type": selectedQuantityType.describe
                  },
                  "weight": {
                    "weight": intParse(weightSaved),
                    "weight_unit": "LB"
                  },
                }
              ],
              "trailer": isReefer
                  ? {
                      "temperature_max": intParse(maxSaved),
                      "temperature_min": intParse(minSaved),
                      "temperature_unit":
                          selectedTempType == TemperatureUnit.C ? "C" : "F",
                    }
                  : null,
            }
          }
        });
      } else {
        runMutation({
          "uuid": uuid,
          "shipment": {
            "short_name": shortSaved,
            "requested_truck_types": [isReefer ? "REEFER" : "DRY_VAN"],
            "accessorials": selectedAccessories,
            "load_description": loadDescSaved,
            "route_distance_miles": distanceMile,
            "route_duration_minutes": transitionTime,
            "stops": stopPoints.map((stop) {
              return {
                "location_profile_id": stop.location.id,
                "appointment_type": stop.appointmentType.describe,
                "start_time": formatISOTime(stop.startTime),
                "end_time": stop.appointmentType == AppointmentType.TO_BE_MADE
                    ? formatISOTime(stop.endTime)
                    : null,
                "type": stop.stopType.describe,
                "loading_type": "LIVE",
                "location_input": {
                  "location_name": stop.location.locationName,
                  "coordinates": stop.location.coordinates.toJson(),
                  "address": stop.location.address.toJson(),
                  "operational_contact":
                      stop.location.operationalContact.toJson(),
                  "scheduling_contact":
                      stop.location.schedulingContact.toJson(),
                }
              };
            }).toList(),
            "items": [
              {
                "description": descSaved,
                "handling_piece": {
                  "piece_type": selectedPackageType.describe,
                  "piece_count": intParse(packingSaved),
                },
                "units": {
                  "unit_count": intParse(quantitySaved),
                  "unit_type": selectedQuantityType.describe
                },
                "weight": {
                  "weight": intParse(weightSaved),
                  "weight_unit": "LB"
                },
              }
            ],
            "trailer": isReefer
                ? {
                    "temperature_max": intParse(maxSaved),
                    "temperature_min": intParse(minSaved),
                    "temperature_unit":
                        selectedTempType == TemperatureUnit.C ? "C" : "F",
                  }
                : null,
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 64.0,
        title: Text(
          isEdit ? 'Edit Shipment' : "Create shipment",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Query(
          options: WatchQueryOptions(
            document: UserLocationsQuery().document,
            fetchPolicy: FetchPolicy.cacheAndNetwork,
            fetchResults: true,
            variables: UserLocationsArguments(
              first: 10,
            ).toJson(),
          ),
          builder: (resultMutation, {refetch, fetchMore}) {
            if (resultMutation.hasException) {
              return GestureDetector(
                onTap: () => refetch(),
                child: Center(
                  child: Text('Something went wrong, tap to try again'),
                ),
              );
            }
            if (resultMutation.isLoading && resultMutation.data == null) {
              return Center(child: const CircularProgressIndicator());
            }

            final a = UserLocations$Query.fromJson(resultMutation.data);
            final locations = a.shipperLocationProfiles.data;
            if (isEdit && isFirst) {
              for (int i = 0; i < stopPoints.length; i++) {
                StopPoint stopPoint = stopPoints[i];
                if (stopPoint.label == 'old' &&
                    locations.any((e) =>
                        e.address.full ==
                        stops[i].locationProfile.address.full))
                  stopPoint.location = locations.firstWhere((e) {
                    return e.address.full ==
                        stops[i].locationProfile.address.full;
                  });
              }
              isFirst = false;
            }

            return Form(
              key: formKey,
              child: CustomScrollView(
                slivers: [
                  // section 1
                  SliverToBoxAdapter(child: Section1()),
                  // section 2
                  SliverToBoxAdapter(child: Section2()),
                  if (_isMultipleStops)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(left: 20, top: 20, right: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12)),
                            icon: Icon(Icons.add_box_outlined),
                            label: Text('Add stop point'),
                            onPressed: () {
                              onAddStopPointTap();
                            },
                          ),
                        ),
                      ),
                    ),
                  if (_isMultipleStops)
                    SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // stops body
                  Section3(locations: locations),
                  SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(child: section4(formKey: formKey)),
                  SliverToBoxAdapter(child: SizedBox(height: 18)),
                  SliverToBoxAdapter(child: FooterSection()),
                  SliverToBoxAdapter(child: SizedBox(height: 18)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget section4({formKey}) {
    return Mutation(
      options: MutationOptions(
        document: CreateShipmentMutation().document,
        errorPolicy: ErrorPolicy.none,
        onCompleted: (dynamic finalData) {
          print('create completed');
          if (finalData != null) {
            id = int.parse(finalData['createOffer']['id']);
            uuid = finalData['createOffer']['uuid'];
            print(uuid);
            onCreated(id, uuid);
          }
        },
        onError: (e) {
          if (e.linkException != null) {
            showSnackbar(
                context,
                'Something went wrong, please check your network connection and try again.',
                false);
            return;
          }

          if (e.graphqlErrors.isNotEmpty) {
            debugPrint(e.graphqlErrors.toString(), wrapWidth: 1024);
          } else {
            showSnackbar(context, 'Something went wrong', false);
          }
        },
      ),
      builder: (runCreateMutation, createResult) {
        isLoading = createResult.isLoading;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Shipment distance:  ',
                    ),
                    if (estimate) getEstimation(true)
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Minimum transit time:  ',
                    ),
                    if (estimate) getEstimation(false)
                  ],
                ),
                const SizedBox(height: 12),
                Mutation(
                    options: MutationOptions(
                      document: UpdateOfferMutation().document,
                      onCompleted: (dynamic resultData) {
                        print('update completed');
                        print(resultData);
                        if (resultData != null) {
                          onCreated(id, uuid);
                        }
                      },
                      onError: (e) {
                        debugPrint(e.toString(), wrapWidth: 1024);
                      },
                    ),
                    builder: (runUpdateMutation, updateResult) {
                      isLoading = updateResult.isLoading;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            onReviewTap(id == null
                                ? runCreateMutation
                                : runUpdateMutation);
                          },
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14)),
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 150),
                            child: (id == null
                                    ? createResult.isLoading
                                    : updateResult.isLoading)
                                ? Theme(
                                    data: Theme.of(context)
                                        .copyWith(accentColor: Colors.white),
                                    child: const ProgressIndicatorSmall(),
                                  )
                                : Text(
                                    'Review Shipment',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }),
              ],
            ),
          ),
        );
      },
    );
  }
}
