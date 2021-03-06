/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI36_0_0RCTScheduler.h"

#import <ABI36_0_0React/debug/SystraceSection.h>
#import <ABI36_0_0React/uimanager/ComponentDescriptorFactory.h>
#import <ABI36_0_0React/uimanager/Scheduler.h>
#import <ABI36_0_0React/uimanager/SchedulerDelegate.h>

#import <ABI36_0_0React/ABI36_0_0RCTFollyConvert.h>

#import "ABI36_0_0RCTConversions.h"

using namespace ABI36_0_0facebook::ABI36_0_0React;

class SchedulerDelegateProxy : public SchedulerDelegate {
 public:
  SchedulerDelegateProxy(void *scheduler) : scheduler_(scheduler) {}

  void schedulerDidFinishTransaction(MountingCoordinator::Shared const &mountingCoordinator) override
  {
    ABI36_0_0RCTScheduler *scheduler = (__bridge ABI36_0_0RCTScheduler *)scheduler_;
    [scheduler.delegate schedulerDidFinishTransaction:mountingCoordinator];
  }

  void schedulerDidRequestPreliminaryViewAllocation(SurfaceId surfaceId, const ShadowView &shadowView) override
  {
    // Does nothing.
    // Preemptive allocation of native views on iOS does not require this call.
  }

  void schedulerDidDispatchCommand(
      const ShadowView &shadowView,
      const std::string &commandName,
      const folly::dynamic args) override
  {
    ABI36_0_0RCTScheduler *scheduler = (__bridge ABI36_0_0RCTScheduler *)scheduler_;
    [scheduler.delegate schedulerDidDispatchCommand:shadowView commandName:commandName args:args];
  }

  void schedulerDidSetJSResponder(
      SurfaceId surfaceId,
      const ShadowView &shadowView,
      const ShadowView &initialShadowView,
      bool blockNativeResponder) override
  {
    // Does nothing for now.
  }

  void schedulerDidClearJSResponder() override
  {
    // Does nothing for now.
  }

 private:
  void *scheduler_;
};

@implementation ABI36_0_0RCTScheduler {
  std::shared_ptr<Scheduler> _scheduler;
  std::shared_ptr<SchedulerDelegateProxy> _delegateProxy;
}

- (instancetype)initWithToolbox:(ABI36_0_0facebook::ABI36_0_0React::SchedulerToolbox)toolbox
{
  if (self = [super init]) {
    _delegateProxy = std::make_shared<SchedulerDelegateProxy>((__bridge void *)self);
    _scheduler = std::make_shared<Scheduler>(toolbox, _delegateProxy.get());
  }

  return self;
}

- (void)dealloc
{
  _scheduler->setDelegate(nullptr);
}

- (void)startSurfaceWithSurfaceId:(SurfaceId)surfaceId
                       moduleName:(NSString *)moduleName
                     initialProps:(NSDictionary *)initialProps
                layoutConstraints:(LayoutConstraints)layoutConstraints
                    layoutContext:(LayoutContext)layoutContext;
{
  SystraceSection s("-[ABI36_0_0RCTScheduler startSurfaceWithSurfaceId:...]");

  auto props = convertIdToFollyDynamic(initialProps);
  _scheduler->startSurface(surfaceId, ABI36_0_0RCTStringFromNSString(moduleName), props, layoutConstraints, layoutContext);
  _scheduler->renderTemplateToSurface(
      surfaceId, props.getDefault("navigationConfig").getDefault("initialUITemplate", "").getString());
}

- (void)stopSurfaceWithSurfaceId:(SurfaceId)surfaceId
{
  SystraceSection s("-[ABI36_0_0RCTScheduler stopSurfaceWithSurfaceId:]");
  _scheduler->stopSurface(surfaceId);
}

- (CGSize)measureSurfaceWithLayoutConstraints:(LayoutConstraints)layoutConstraints
                                layoutContext:(LayoutContext)layoutContext
                                    surfaceId:(SurfaceId)surfaceId
{
  SystraceSection s("-[ABI36_0_0RCTScheduler measureSurfaceWithLayoutConstraints:]");
  return ABI36_0_0RCTCGSizeFromSize(_scheduler->measureSurface(surfaceId, layoutConstraints, layoutContext));
}

- (void)constraintSurfaceLayoutWithLayoutConstraints:(LayoutConstraints)layoutConstraints
                                       layoutContext:(LayoutContext)layoutContext
                                           surfaceId:(SurfaceId)surfaceId
{
  SystraceSection s("-[ABI36_0_0RCTScheduler constraintSurfaceLayoutWithLayoutConstraints:]");
  _scheduler->constraintSurfaceLayout(surfaceId, layoutConstraints, layoutContext);
}

- (const ComponentDescriptor &)getComponentDescriptor:(ComponentHandle)handle
{
  return _scheduler->getComponentDescriptor(handle);
}

@end
